let () =
  Printexc.record_backtrace true ;
  if Array.length Sys.argv < 2 then exit 1 ;
  let inFilename = Sys.argv.(1) in
  let comp =
    let%lwt outFilename = Rrun.BuildSystem.build inFilename in
    Lwt.return outFilename
  in
  let exePath = Lwt_main.run comp in
  Unix.execv (Fpath.to_string exePath) Sys.argv
