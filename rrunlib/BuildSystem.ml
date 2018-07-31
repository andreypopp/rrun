let homePath = Fpath.(v "/Users/andreypopp")

let storePath = Fpath.(homePath / ".rrun")

let currentPath = Fpath.(v (Sys.getcwd ()))

module Deps : sig
  type dep = {id: string; spec: string; path: Fpath.t}

  type t = dep list

  val of_file : Fpath.t -> t Lwt.t
end = struct
  module Format = struct
    open Sexplib0.Sexp_conv

    type t = (string * string * string) list [@@deriving sexp]
  end

  type t = dep list

  and dep = {id: string; spec: string; path: Fpath.t}

  let of_file path =
    let%lwt data = Fs.read_file path in
    if String.length data = 0 then Lwt.return []
    else
      match Sexplib.Sexp.of_string data with
      | Sexplib.Sexp.(List [Atom "deps"; deps]) ->
          let items = Format.t_of_sexp deps in
          let f (id, spec, path) = {id; spec; path= Fpath.v path} in
          Lwt.return (List.map f items)
      | _ -> raise (Invalid_argument "invalid dependency format")
end

let makeId spec =
  let len = String.length spec in
  let rec aux acc idx =
    if idx = len then acc |> List.rev |> String.concat ""
    else
      let chunk =
        match spec.[idx] with
        | '.' -> "S_DT_"
        | '/' -> "S_SL_"
        | '@' -> "S_AT_"
        | '_' -> "S_UN_"
        | '-' -> "S_DH_"
        | ' ' -> "S_SP_"
        | ':' -> "S_CL_"
        | ';' -> "S_SC_"
        | c -> String.make 1 c
      in
      aux (chunk :: acc) (idx + 1)
  in
  aux [] 0

module Process = struct
  let run ?env (cmd: Cmd.t) =
    let f (p: Lwt_process.process_full) =
      let%lwt stderr =
        Lwt.finalize
          (fun () -> Lwt_io.read p#stderr)
          (fun () -> Lwt_io.close p#stderr)
      in
      let%lwt stdout =
        Lwt.finalize
          (fun () -> Lwt_io.read p#stdout)
          (fun () -> Lwt_io.close p#stdout)
      in
      match%lwt p#status with
      | Unix.WEXITED 0 -> Lwt.return ()
      | Unix.WEXITED _ ->
          Format.printf "command failed: %a@\n%s@\n%s" Cmd.pp cmd stdout stderr ;
          failwith "command failed"
      | _ -> failwith "error running subprocess"
    in
    let cmd = Cmd.tool_and_line cmd in
    let env =
      match env with
      | Some env -> Some (Array.append (Unix.environment ()) env)
      | None -> None
    in
    Lwt_process.with_process_full ?env cmd f
end

module Module : sig
  type t =
    { id: string
    ; path: Fpath.t
    ; objPath: Fpath.t
    ; exePath: Fpath.t
    ; srcPath: Fpath.t
    ; depPath: Fpath.t
    ; state: state }

  and state = New | Stale | Ready

  val ofPath : Fpath.t -> t Lwt.t

  val build : t -> t Lwt.t
end = struct
  type t =
    { id: string
    ; path: Fpath.t
    ; objPath: Fpath.t
    ; exePath: Fpath.t
    ; srcPath: Fpath.t
    ; depPath: Fpath.t
    ; state: state }

  and state = New | Stale | Ready

  let checkState ~out_path in_path =
    match%lwt Fs.stat out_path with
    | exception Unix.Unix_error (Unix.ENOENT, _, _) -> Lwt.return New
    | {Unix.st_mtime= out_mtime; _} ->
        let%lwt {Unix.st_mtime= in_mtime; _} = Fs.stat in_path in
        if out_mtime < in_mtime then Lwt.return Stale else Lwt.return Ready

  let ofPath path =
    let id = makeId (Fpath.to_string path) in
    let srcPath = Fpath.(storePath / id |> add_ext ".ml") in
    let depPath = Fpath.(storePath / id |> add_ext ".dep") in
    let exePath = Fpath.(storePath / id |> add_ext ".exe") in
    let objPath = Fpath.(storePath / id |> add_ext ".cmx") in
    let%lwt state = checkState ~out_path:srcPath path in
    Lwt.return {id; path; objPath; exePath; srcPath; depPath; state}

  let promote m =
    match m.state with
    | Stale | New ->
        Fs.create_dir Fpath.(parent m.srcPath) ;%lwt
        Fs.copy_file ~src_path:m.path m.srcPath ;%lwt
        Lwt.return {m with state= Stale}
    | Ready -> Lwt.return m

  let extractDependencies (m: t) =
    match m.state with
    | Ready -> Deps.of_file m.depPath
    | Stale | New ->
        let%lwt m = promote m in
        let%lwt () =
          let cmd =
            let open Cmd in
            v "rrundep" % "-loc-filename" % p m.path % "-output-metadata"
            % p m.depPath % "-impl" % p m.srcPath
          in
          Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string m.path|] cmd
        in
        Deps.of_file m.depPath

  let build m =
    let buildObj ~force m =
      let work () =
        prerr_endline ("[b obj] " ^ Fpath.to_string m.path) ;
        let cmd =
          let ppx =
            Cmd.(v "rrundep" % "-as-ppx" % "-loc-filename" % p m.path)
          in
          let open Cmd in
          v "ocamlopt" % "-verbose" % "-c" % "-I" % p storePath % "-ppx"
          % Cmd.to_string ppx % p m.srcPath
        in
        Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string m.path|] cmd ;%lwt
        Lwt.return true
      in
      match%lwt checkState ~out_path:m.objPath m.path with
      | New | Stale -> work ()
      | Ready -> if force then work () else Lwt.return false
    in
    let buildExe ~force exePath objs =
      let work () =
        prerr_endline ("[b exe] " ^ Fpath.to_string m.path) ;
        let cmd =
          let cmd = Cmd.(v "ocamlopt" % "-verbose" % "-o" % p exePath) in
          let f cmd obj = Cmd.(cmd % p obj) in
          List.fold_left f cmd objs
        in
        Process.run ~env:[|"RRUN_FILENAME=" ^ Fpath.to_string m.path|] cmd
      in
      match%lwt checkState ~out_path:m.exePath m.path with
      | New | Stale -> work ()
      | Ready -> if force then work () else Lwt.return ()
    in
    let rec batchBuildObj (needRebuild, seen, objs) m =
      (* prerr_endline ("[->] " ^ Fpath.to_string m.path) ; *)
      let%lwt deps = extractDependencies m in
      let%lwt needRebuild, seen, objs =
        let buildDep (n, seen, objs) (dep: Deps.dep) =
          let%lwt m = ofPath dep.path in
          let%lwt nn, seen, objs = batchBuildObj (needRebuild, seen, objs) m in
          Lwt.return (n || nn, seen, objs)
        in
        Lwt_list.fold_left_s buildDep (needRebuild, seen, objs) deps
      in
      let%lwt thisNeedRebuild = buildObj ~force:needRebuild m in
      let thisWasRebuild =
        match Fpath.Map.find_opt m.objPath seen with
        | Some v -> v
        | None -> false
      in
      let%lwt needRebuild =
        Lwt.return (needRebuild || thisNeedRebuild || thisWasRebuild)
      in
      let objs =
        if Fpath.Map.mem m.objPath seen then objs else m.objPath :: objs
      in
      let seen = Fpath.Map.add m.objPath thisNeedRebuild seen in
      (* prerr_endline ("[<-] " ^ Fpath.to_string m.path) ; *)
      Lwt.return (needRebuild, seen, objs)
    in
    let%lwt needRebuild, _seen, objs =
      batchBuildObj (false, Fpath.Map.empty, []) m
    in
    buildExe ~force:needRebuild m.exePath (List.rev objs) ;%lwt Lwt.return m
end

let resolve spec basePath = Fpath.(basePath // v spec |> normalize)

let build root =
  let root = resolve root currentPath in
  let%lwt root = Module.ofPath root in
  let%lwt built = Module.build root in
  Lwt.return built.exePath
