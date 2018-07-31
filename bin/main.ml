module Api = struct
  let build path =
    let comp =
      let%lwt outFilename = Rrun.BuildSystem.build path in
      Lwt.return outFilename
    in
    let _ = Lwt_main.run comp in
    `Ok ()

  let default path =
    let comp =
      let%lwt outFilename = Rrun.BuildSystem.build path in
      Lwt.return outFilename
    in
    let exePath = Lwt_main.run comp in
    Unix.execv (Fpath.to_string exePath) Sys.argv

  let merlin =
    {|
B /Users/andreypopp/.rrun
S /Users/andreypopp/.rrun
S .
FLG -ppx 'rrundep --as-ppx'
FLG -w @a-4-29-40-41-42-44-45-48-58-59-60-40 -strict-sequence -strict-formats -short-paths -keep-locs
|}

  let generate_merlin () = print_endline merlin ; `Ok ()

  let edit path =
    let editor = try Sys.getenv "EDITOR" with Not_found -> "vi" in
    let parent = Fpath.(parent path / ".merlin") in
    let oc = open_out (Fpath.to_string parent) in
    output_string oc merlin ;
    close_out oc ;
    Unix.execv editor [|editor; Fpath.to_string path|]
end

open Cmdliner

let path =
  let parse = Fpath.of_string in
  let print = Fpath.pp in
  Arg.conv ~docv:"PATH" (parse, print)

let program_arg =
  let doc = "Program" in
  Arg.(required & pos 0 (some path) None & info [] ~docv:"PROGRAM" ~doc)

let default_cmd =
  let doc = "Run program." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let info = Term.info "rrun" ~doc ~sdocs ~exits in
  (Term.(ret (const Api.default $ program_arg)), info)

let build_cmd =
  let doc = "Build program." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let info = Term.info "build" ~doc ~sdocs ~exits in
  (Term.(ret (const Api.build $ program_arg)), info)

let run_cmd =
  let doc = "Build and run program." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let info = Term.info "run" ~doc ~sdocs ~exits in
  (Term.(ret (const Api.default $ program_arg)), info)

let merlin_cmd =
  let doc = "Generate .merlin file." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let info = Term.info "gen-merlin" ~doc ~sdocs ~exits in
  (Term.(ret (const Api.generate_merlin $ const ())), info)

let edit_cmd =
  let doc = "Edit program." in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let info = Term.info "edit" ~doc ~sdocs ~exits in
  (Term.(ret (const Api.edit $ program_arg)), info)

let cmds = [run_cmd; build_cmd; merlin_cmd; edit_cmd]

let () =
  Printexc.record_backtrace true ;
  (* fixup args so we can use default invocation for run *)
  let argv =
    match Sys.argv.(1) with
    | exception Invalid_argument _ -> Sys.argv
    | "" | "build" | "run" | "gen-merlin" | "edit" | "--" -> Sys.argv
    | w ->
        if w.[0] = '-' then Sys.argv
        else
          let argv = Array.make (Array.length Sys.argv + 1) "" in
          argv.(0) <- Sys.argv.(0) ;
          argv.(1) <- "--" ;
          let copy_arg i v = if i >= 1 then argv.(i + 1) <- v else () in
          Array.iteri copy_arg Sys.argv ;
          argv
  in
  Term.(exit @@ eval_choice ~argv default_cmd cmds)
