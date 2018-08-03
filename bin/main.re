open Rrun;

module Api = {
  let build = (cfg, path) => {
    let comp = {
      let%lwt outFilename = Rrun.BuildSystem.build(~cfg, path);
      Lwt.return(outFilename);
    };

    let _ = Lwt_main.run(comp);
    `Ok();
  };

  let default = (cfg, path) => {
    let comp = {
      let%lwt outFilename = Rrun.BuildSystem.build(~cfg, path);
      Lwt.return(outFilename);
    };

    let exePath = Lwt_main.run(comp);
    Unix.execv(Fpath.to_string(exePath), Sys.argv);
  };

  let merlin = cfg =>
    Format.asprintf(
      {|
B %a
S %a
FLG -ppx 'rrundep --as-ppx'
FLG -w @a-4-29-40-41-42-44-45-48-58-59-60-40 -strict-sequence -strict-formats -short-paths -keep-locs
|},
      Fpath.pp,
      cfg.Config.store_path,
      Fpath.pp,
      cfg.Config.store_path,
    );

  let generate_merlin = cfg => {
    print_endline(merlin(cfg));
    `Ok();
  };

  let edit = (cfg, path) => {
    let editor =
      try (Sys.getenv("EDITOR")) {
      | Not_found => "vi"
      };
    let parent = Fpath.(parent(path) / ".merlin");
    let oc = open_out(Fpath.to_string(parent));
    output_string(oc, merlin(cfg));
    close_out(oc);
    Unix.execv(editor, [|editor, Fpath.to_string(path)|]);
  };
};

open Cmdliner;

let path = {
  let parse = Fpath.of_string;
  let print = Fpath.pp;
  Arg.conv(~docv="PATH", (parse, print));
};

let program_arg = {
  let doc = "Program";
  Arg.(
    required & pos(0, some(path), None) & info([], ~docv="PROGRAM", ~doc)
  );
};

let config_arg = {
  let init_config = () => Lwt_main.run(Config.init());

  Term.(const(init_config) $ const());
};

let default_cmd = {
  let doc = "Run program.";
  let sdocs = Manpage.s_common_options;
  let exits = Term.default_exits;
  let info = Term.info("rrun", ~doc, ~sdocs, ~exits);
  (Term.(ret(const(Api.default) $ config_arg $ program_arg)), info);
};

let build_cmd = {
  let doc = "Build program.";
  let sdocs = Manpage.s_common_options;
  let exits = Term.default_exits;
  let info = Term.info("build", ~doc, ~sdocs, ~exits);
  (Term.(ret(const(Api.build) $ config_arg $ program_arg)), info);
};

let run_cmd = {
  let doc = "Build and run program.";
  let sdocs = Manpage.s_common_options;
  let exits = Term.default_exits;
  let info = Term.info("run", ~doc, ~sdocs, ~exits);
  (Term.(ret(const(Api.default) $ config_arg $ program_arg)), info);
};

let merlin_cmd = {
  let doc = "Generate .merlin file.";
  let sdocs = Manpage.s_common_options;
  let exits = Term.default_exits;
  let info = Term.info("gen-merlin", ~doc, ~sdocs, ~exits);
  (Term.(ret(const(Api.generate_merlin) $ config_arg)), info);
};

let edit_cmd = {
  let doc = "Edit program.";
  let sdocs = Manpage.s_common_options;
  let exits = Term.default_exits;
  let info = Term.info("edit", ~doc, ~sdocs, ~exits);
  (Term.(ret(const(Api.edit) $ config_arg $ program_arg)), info);
};

let cmds = [run_cmd, build_cmd, merlin_cmd, edit_cmd];

let () = {
  Printexc.record_backtrace(true);
  /* fixup args so we can use default invocation for run */
  let argv =
    switch (Sys.argv[1]) {
    | exception (Invalid_argument(_)) => Sys.argv
    | ""
    | "build"
    | "run"
    | "gen-merlin"
    | "edit"
    | "--" => Sys.argv
    | w =>
      if (w.[0] == '-') {
        Sys.argv;
      } else {
        let argv = Array.make(Array.length(Sys.argv) + 1, "");
        argv[0] = Sys.argv[0];
        argv[1] = "--";
        let copy_arg = (i, v) =>
          if (i >= 1) {
            argv[i + 1] = v;
          } else {
            ();
          };
        Array.iteri(copy_arg, Sys.argv);
        argv;
      }
    };

  Term.(exit @@ eval_choice(~argv, default_cmd, cmds));
};
