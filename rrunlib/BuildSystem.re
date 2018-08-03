module Module: {
  type t = {
    id: string,
    kind,
    src: Source.t,
    obj_path: Fpath.t,
    exe_path: Fpath.t,
    src_path: Fpath.t,
    dep_path: Fpath.t,
  }
  and kind =
    | OCaml
    | Reason;

  let make: (~cfg: Config.t, Source.t) => t;
  let label: t => string;
  let orig_src_path: t => Fpath.t;
} = {
  type t = {
    id: string,
    kind,
    src: Source.t,
    obj_path: Fpath.t,
    exe_path: Fpath.t,
    src_path: Fpath.t,
    dep_path: Fpath.t,
  }
  and kind =
    | OCaml
    | Reason;

  let label = m =>
    switch (m.src) {
    | Path(path) => Fpath.to_string(path)
    | Https(uri) => Uri.to_string(uri)
    };

  let make = (~cfg, src) => {
    let id = Source.id(src);
    let kind =
      switch (src) {
      | Path(path) =>
        switch (Fpath.get_ext(path)) {
        | "re"
        | ".re" => Reason
        | "ml"
        | ".ml" => OCaml
        | _ => failwith("unknown module kind: " ++ Fpath.to_string(path))
        }
      | Https(_) => OCaml
      };

    let src_path = Fpath.(cfg.Config.store_path / id |> add_ext(".ml"));
    let dep_path = Fpath.(cfg.Config.store_path / id |> add_ext(".dep"));
    let exe_path = Fpath.(cfg.Config.store_path / id |> add_ext(".exe"));
    let obj_path = Fpath.(cfg.Config.store_path / id |> add_ext(".cmx"));
    {id, kind, src, obj_path, exe_path, src_path, dep_path};
  };

  let orig_src_path = m =>
    switch (m.src) {
    | Path(path) => path
    | Https(_) => m.src_path
    };
};

type staleness =
  | New
  | Stale
  | Ready;

let check_staleness = (~out_path, in_path) =>
  switch%lwt (Fs.stat(out_path)) {
  | exception ([@implicit_arity] Unix.Unix_error(Unix.ENOENT, _, _)) =>
    Lwt.return(New)
  | {Unix.st_mtime: out_mtime, _} =>
    let%lwt {Unix.st_mtime: in_mtime, _} = Fs.stat(in_path);
    if (out_mtime < in_mtime) {
      Lwt.return(Stale);
    } else {
      Lwt.return(Ready);
    };
  };

let fetch_to_store = (m: Module.t) =>
  switch (m.src) {
  | Source.Path(path) =>
    switch%lwt (check_staleness(~out_path=m.src_path, path)) {
    | Stale
    | New =>
      let before = (oc, _ic) =>
        Lwt_io.write(oc, "# 1 \"" ++ Fpath.to_string(path) ++ "\"\n");

      %lwt
      {
        Fs.copy_file(~before, ~src_path=path, m.src_path);
        Lwt.return();
      };
    | Ready => Lwt.return()
    }
  | Source.Https(uri) =>
    if%lwt (Fs.exists(m.src_path)) {
      Lwt.return();
    } else {
      prerr_endline("[<- src] " ++ Module.label(m));
      Process.run(
        Cmd.(
          v("curl")
          % "--silent"
          % "--fail"
          % "--location"
          % Uri.to_string(uri)
          % "--output"
          % p(m.src_path)
        ),
      );
    }
  };

let extract_dependencies = (~cfg, m: Module.t) => {
  let path = Module.orig_src_path(m);
  switch%lwt (check_staleness(~out_path=m.dep_path, path)) {
  | Ready => DepsMeta.of_file(m.dep_path)
  | Stale
  | New =>
    %lwt
    {
      fetch_to_store(m);
      let%lwt cmd =
        switch (m.kind) {
        | OCaml =>
          Lwt.return(
            Cmd.(
              v("rrundep")
              % "-loc-filename"
              % p(path)
              % "-output-metadata"
              % p(m.dep_path)
              % "-impl"
              % p(m.src_path)
            ),
          )
        | Reason =>
          let ppPath = Fpath.(cfg.Config.store_path / (m.id ++ "__ml.ml"));
          %lwt
          {
            Fs.copy_file(~src_path=m.src_path, ppPath);
            %lwt
            {
              Process.run(
                Cmd.(
                  v("refmt")
                  % "--parse"
                  % "re"
                  % "--print"
                  % "binary"
                  % "--in-place"
                  % p(ppPath)
                ),
              );
              Lwt.return(
                Cmd.(
                  v("rrundep")
                  % "-loc-filename"
                  % p(path)
                  % "-output-metadata"
                  % p(m.dep_path)
                  % "-impl"
                  % p(ppPath)
                ),
              );
            };
          };
        };

      let baseS = m.src |> Source.sexp_of_t |> Sexplib.Sexp.to_string;

      %lwt
      {
        Process.run(~env=[|"RRUN_BASE=" ++ baseS|], cmd);
        DepsMeta.of_file(m.dep_path);
      };
    }
  };
};

let build = (~cfg, m: Module.t) => {
  let buildObj = (~force, m: Module.t) => {
    let work = () => {
      prerr_endline("[b obj] " ++ Module.label(m));
      let cmd = {
        let rrundep_ppx = Cmd.(v("rrundep") % "-as-ppx");
        let pp_refmt =
          Cmd.(v("refmt") % "--parse" % "re" % "--print" % "binary");

        let default_args = [
          "-verbose",
          "-short-paths",
          "-keep-locs",
          "-bin-annot",
        ];

        let cmd = {
          let cmd = Cmd.(v("ocamlopt") |> add_args(default_args));
          let cmd = Cmd.(cmd % "-c" % "-I" % p(cfg.Config.store_path));
          let cmd =
            switch (m.kind) {
            | Reason => Cmd.(cmd % "-pp" % Cmd.to_string(pp_refmt))
            | OCaml => cmd
            };

          Cmd.(cmd % "-ppx" % Cmd.to_string(rrundep_ppx) % p(m.src_path));
        };

        cmd;
      };

      let baseS = m.src |> Source.sexp_of_t |> Sexplib.Sexp.to_string;

      %lwt
      {
        Process.run(~env=[|"RRUN_BASE=" ++ baseS|], cmd);
        Lwt.return(true);
      };
    };

    switch%lwt (
      check_staleness(~out_path=m.obj_path, Module.orig_src_path(m))
    ) {
    | New
    | Stale => work()
    | Ready =>
      if (force) {
        work();
      } else {
        Lwt.return(false);
      }
    };
  };

  let buildExe = (~force, exe_path, objs) => {
    let work = () => {
      prerr_endline("[b exe] " ++ Module.label(m));
      let cmd = {
        let cmd =
          Cmd.(
            v("ocamlopt")
            % "-short-paths"
            % "-keep-locs"
            % "-o"
            % p(exe_path)
          );

        let f = (cmd, obj) => Cmd.(cmd % p(obj));
        List.fold_left(f, cmd, objs);
      };

      Process.run(
        ~env=[|
          "RRUN_FILENAME=" ++ Fpath.to_string(Module.orig_src_path(m)),
        |],
        cmd,
      );
    };

    switch%lwt (
      check_staleness(~out_path=m.exe_path, Module.orig_src_path(m))
    ) {
    | New
    | Stale => work()
    | Ready =>
      if (force) {
        work();
      } else {
        Lwt.return();
      }
    };
  };

  let rec batchBuildObj = ((needRebuild, seen, objs), m) => {
    /* prerr_endline ("[->] " ^ Fpath.to_string m.path) ; */
    let%lwt deps = extract_dependencies(~cfg, m);
    let%lwt (needRebuild, seen, objs) = {
      let buildDep = ((n, seen, objs), dep: DepsMeta.dep) => {
        let m = Module.make(~cfg, dep.src);
        let%lwt (nn, seen, objs) =
          batchBuildObj((needRebuild, seen, objs), m);
        Lwt.return((n || nn, seen, objs));
      };

      Lwt_list.fold_left_s(buildDep, (needRebuild, seen, objs), deps);
    };

    let%lwt thisNeedRebuild = buildObj(~force=needRebuild, m);
    let thisWasRebuild =
      switch (Fpath.Map.find_opt(m.obj_path, seen)) {
      | Some(v) => v
      | None => false
      };

    let%lwt needRebuild =
      Lwt.return(needRebuild || thisNeedRebuild || thisWasRebuild);

    let objs =
      if (Fpath.Map.mem(m.obj_path, seen)) {
        objs;
      } else {
        [m.obj_path, ...objs];
      };

    let seen = Fpath.Map.add(m.obj_path, thisNeedRebuild, seen);
    /* prerr_endline ("[<-] " ^ Fpath.to_string m.path) ; */
    Lwt.return((needRebuild, seen, objs));
  };

  let%lwt (needRebuild, _seen, objs) =
    batchBuildObj((false, Fpath.Map.empty, []), m);

  %lwt
  {
    buildExe(~force=needRebuild, m.exe_path, List.rev(objs));
    Lwt.return(m);
  };
};

let resolve = (~base=?, spec) => {
  let https_re = Str.regexp("^https:");
  if (Str.string_match(https_re, spec, 0)) {
    Source.Https(Uri.of_string(spec));
  } else {
    switch (base) {
    | Some(Source.Path(base_path)) =>
      Source.Path(Fpath.(parent(base_path) /\/ v(spec) |> normalize))
    | Some(Source.Https(uri)) =>
      let base_path = Fpath.v(Uri.path(uri));
      let path = Fpath.(parent(base_path) /\/ v(spec) |> normalize);
      let uri = Uri.with_path(uri, Fpath.to_string(path));
      Source.Https(uri);
    | None =>
      Source.Path(Fpath.(System.currentPath /\/ v(spec) |> normalize))
    };
  };
};

let build = (~cfg, root) => {
  let root = resolve(Fpath.to_string(root));
  let root = Module.make(~cfg, root);
  let%lwt built = build(~cfg, root);
  Lwt.return(built.exe_path);
};
