module Module : sig
  type t = {
    id: string;
    kind: kind;
    src : Source.t;
    obj_path: Fpath.t;
    exe_path: Fpath.t;
    src_path: Fpath.t;
    dep_path: Fpath.t;
  }

  and kind =
    | OCaml
    | Reason

  val make : cfg:Config.t -> Source.t -> t
  val label : t -> string
  val orig_src_path : t -> Fpath.t
end = struct
  type t = {
    id : string;
    kind : kind;
    src : Source.t;
    obj_path : Fpath.t;
    exe_path : Fpath.t;
    src_path : Fpath.t;
    dep_path : Fpath.t;
  }

  and kind =
    | OCaml
    | Reason

  let label m =
    match m.src with
    | Path path -> Fpath.to_string path
    | Https url -> url

  let make ~cfg src =
    let id = Source.id src in
    let kind =
      match src with
      | Path path ->
        begin match Fpath.get_ext path with
        | "re" | ".re" -> Reason
        | "ml" | ".ml" -> OCaml
        | _ -> failwith ("unknown module kind: " ^ Fpath.to_string path)
        end
      | Https _ -> OCaml
    in
    let src_path = Fpath.(cfg.Config.store_path / id |> add_ext ".ml") in
    let dep_path = Fpath.(cfg.Config.store_path / id |> add_ext ".dep") in
    let exe_path = Fpath.(cfg.Config.store_path / id |> add_ext ".exe") in
    let obj_path = Fpath.(cfg.Config.store_path / id |> add_ext ".cmx") in
    {id; kind; src; obj_path; exe_path; src_path; dep_path;}

  let orig_src_path m =
    match m.src with
    | Path path -> path
    | Https _ -> m.src_path
end

type staleness = New | Stale | Ready

let check_staleness ~out_path in_path =
  match%lwt Fs.stat out_path with
  | exception Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return New
  | {Unix.st_mtime= out_mtime; _} ->
      let%lwt {Unix.st_mtime= in_mtime; _} = Fs.stat in_path in
      if out_mtime < in_mtime then Lwt.return Stale else Lwt.return Ready

let fetch_to_store (m : Module.t) =
  match m.src with
  | Source.Path path ->
    begin match%lwt check_staleness ~out_path:m.src_path path with
    | Stale | New ->
      let before oc _ic =
        Lwt_io.write oc ("# 1 \"" ^ Fpath.to_string path ^ "\"\n")
      in
      Fs.copy_file ~before ~src_path:path m.src_path ;%lwt
      Lwt.return ()
    | Ready -> Lwt.return ()
    end
  | Source.Https url ->
    if%lwt Fs.exists m.src_path
    then Lwt.return ()
    else (
      prerr_endline ("[<- src] " ^ Module.label m) ;
      Process.run Cmd.(
        v "curl"
        % "--silent"
        % "--fail"
        % "--location"
        % url
        % "--output" % p m.src_path
      )
    )

let extract_dependencies ~cfg (m : Module.t) =
  let path = Module.orig_src_path m in
  match%lwt check_staleness ~out_path:m.dep_path path with
  | Ready -> DepsMeta.of_file m.dep_path
  | Stale
  | New ->
    fetch_to_store m;%lwt
    let%lwt cmd =
      match m.kind with
      | OCaml ->
        Lwt.return Cmd.(
          v "rrundep"
          % "-loc-filename" % p path
          % "-output-metadata" % p m.dep_path
          % "-impl" % p m.src_path
        )
      | Reason ->
        let ppPath = Fpath.(cfg.Config.store_path / (m.id ^ "__ml.ml")) in
        Fs.copy_file ~src_path:m.src_path ppPath;%lwt
        Process.run Cmd.(
          v "refmt"
          % "--parse" % "re"
          % "--print" % "binary"
          % "--in-place"
          % p ppPath
        );%lwt
        Lwt.return Cmd.(
          v "rrundep"
          % "-loc-filename" % p path
          % "-output-metadata" % p m.dep_path
          % "-impl" % p ppPath
        )
    in
    Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string path|] cmd;%lwt
    DepsMeta.of_file m.dep_path

let build ~cfg (m : Module.t) =

  let buildObj ~force (m : Module.t) =
    let work () =
      prerr_endline ("[b obj] " ^ Module.label m) ;
      let cmd =
        let rrundep_ppx = Cmd.(v "rrundep" % "-as-ppx") in
        let pp_refmt =
          Cmd.(v "refmt" % "--parse" % "re" % "--print" % "binary")
        in
        let default_args =
          ["-verbose"; "-short-paths"; "-keep-locs"; "-bin-annot"]
        in
        let cmd =
          let cmd = Cmd.(v "ocamlopt" |> add_args default_args) in
          let cmd = Cmd.(cmd % "-c" % "-I" % p cfg.Config.store_path) in
          let cmd =
            match m.kind with
            | Reason -> Cmd.(cmd % "-pp" % Cmd.to_string pp_refmt)
            | OCaml -> cmd
          in
          Cmd.(cmd % "-ppx" % Cmd.to_string rrundep_ppx % p m.src_path)
        in
        cmd
      in
      Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string (Module.orig_src_path m)|] cmd ;%lwt
      Lwt.return true
    in
    match%lwt check_staleness ~out_path:m.obj_path (Module.orig_src_path m) with
    | New
    | Stale ->
      work ()
    | Ready ->
      if force
      then work ()
      else Lwt.return false
  in

  let buildExe ~force exe_path objs =
    let work () =
      prerr_endline ("[b exe] " ^ Module.label m) ;
      let cmd =
        let cmd =
          Cmd.(v "ocamlopt" % "-short-paths" % "-keep-locs" % "-o" % p exe_path)
        in
        let f cmd obj = Cmd.(cmd % p obj) in
        List.fold_left f cmd objs
      in
      Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string (Module.orig_src_path m)|] cmd
    in
    match%lwt check_staleness ~out_path:m.exe_path (Module.orig_src_path m) with
    | New
    | Stale ->
      work ()
    | Ready ->
      if force
      then work ()
      else Lwt.return ()
  in

  let rec batchBuildObj (needRebuild, seen, objs) m =
    (* prerr_endline ("[->] " ^ Fpath.to_string m.path) ; *)
    let%lwt deps = extract_dependencies ~cfg m in
    let%lwt needRebuild, seen, objs =
      let buildDep (n, seen, objs) (dep: DepsMeta.dep) =
        let m = Module.make ~cfg dep.src in
        let%lwt nn, seen, objs = batchBuildObj (needRebuild, seen, objs) m in
        Lwt.return (n || nn, seen, objs)
      in
      Lwt_list.fold_left_s buildDep (needRebuild, seen, objs) deps
    in
    let%lwt thisNeedRebuild = buildObj ~force:needRebuild m in
    let thisWasRebuild =
      match Fpath.Map.find_opt m.obj_path seen with
      | Some v -> v
      | None -> false
    in
    let%lwt needRebuild =
      Lwt.return (needRebuild || thisNeedRebuild || thisWasRebuild)
    in
    let objs =
      if Fpath.Map.mem m.obj_path seen then objs else m.obj_path :: objs
    in
    let seen = Fpath.Map.add m.obj_path thisNeedRebuild seen in
    (* prerr_endline ("[<-] " ^ Fpath.to_string m.path) ; *)
    Lwt.return (needRebuild, seen, objs)
  in

  let%lwt needRebuild, _seen, objs =
    batchBuildObj (false, Fpath.Map.empty, []) m
  in

  buildExe ~force:needRebuild m.exe_path (List.rev objs) ;%lwt Lwt.return m

let resolve spec base_path =
  let https_re = Str.regexp "^https:" in
  if Str.string_match https_re spec 0
  then Source.Https spec
  else Source.Path (Fpath.(base_path // v spec |> normalize))

let build ~cfg root =
  let root = resolve (Fpath.to_string root) System.currentPath in
  let root = Module.make ~cfg root in
  let%lwt built = build ~cfg root in
  Lwt.return built.exe_path
