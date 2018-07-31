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
