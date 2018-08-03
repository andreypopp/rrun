let run = (~env=?, cmd: Cmd.t) => {
  let f = (p: Lwt_process.process_full) => {
    let%lwt stderr =
      Lwt.finalize(
        () => Lwt_io.read(p#stderr),
        () => Lwt_io.close(p#stderr),
      );

    let%lwt stdout =
      Lwt.finalize(
        () => Lwt_io.read(p#stdout),
        () => Lwt_io.close(p#stdout),
      );

    switch%lwt (p#status) {
    | Unix.WEXITED(0) => Lwt.return()
    | Unix.WEXITED(_) =>
      Format.printf(
        "command failed: %a@\n%s@\n%s",
        Cmd.pp,
        cmd,
        stdout,
        stderr,
      );
      failwith("command failed");
    | _ => failwith("error running subprocess")
    };
  };

  let cmd = Cmd.tool_and_line(cmd);
  let env =
    switch (env) {
    | Some(env) => Some(Array.append(Unix.environment(), env))
    | None => None
    };

  Lwt_process.with_process_full(~env?, cmd, f);
};
