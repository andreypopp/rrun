let stat = path => {
  let path = Fpath.to_string(path);
  Lwt_unix.stat(path);
};

let exists = path => {
  let path = Fpath.to_string(path);
  switch%lwt (Lwt_unix.stat(path)) {
  | exception ([@implicit_arity] Unix.Unix_error(Unix.ENOENT, _, _)) =>
    Lwt.return(false)
  | _ => Lwt.return(true)
  };
};

let copy_stats = (~stat, path) => {
  let chown = (path, uid, gid) =>
    try%lwt (Lwt_unix.chown(path, uid, gid)) {
    | [@implicit_arity] Unix.Unix_error(Unix.EPERM, _, _) => Lwt.return()
    };

  let path = Fpath.to_string(path);
  let%lwt () = Lwt_unix.utimes(path, stat.Unix.st_atime, stat.Unix.st_mtime);
  let%lwt () = Lwt_unix.chmod(path, stat.Unix.st_perm);
  let%lwt () = chown(path, stat.Unix.st_uid, stat.Unix.st_gid);
  Lwt.return();
};

let read_file = path => {
  let path = Fpath.to_string(path);
  Lwt_io.with_file(~mode=Lwt_io.Input, path, ic => Lwt_io.read(ic));
};

let copy_file = (~before=?, ~src_path, dst_path) => {
  let origPathS = Fpath.to_string(src_path);
  let destPathS = Fpath.to_string(dst_path);
  let chunkSize = 1024 * 1024 /* 1mb */;
  let%lwt stat = Lwt_unix.stat(origPathS);
  let copy = (ic, oc) => {
    let buffer = Bytes.create(chunkSize);
    let%lwt () =
      switch (before) {
      | Some(before) => before(oc, ic)
      | None => Lwt.return()
      };

    let rec loop = () =>
      switch%lwt (Lwt_io.read_into(ic, buffer, 0, chunkSize)) {
      | 0 => Lwt.return()
      | bytesRead =>
        let%lwt () = Lwt_io.write_from_exactly(oc, buffer, 0, bytesRead);
        loop();
      };

    loop();
  };

  let%lwt () =
    Lwt_io.with_file(
      origPathS, ~flags=Lwt_unix.[O_RDONLY], ~mode=Lwt_io.Input, ic =>
      Lwt_io.with_file(
        ~mode=Lwt_io.Output,
        ~flags=Lwt_unix.[O_WRONLY, O_CREAT, O_TRUNC],
        ~perm=stat.Unix.st_perm,
        destPathS,
        copy(ic),
      )
    );

  let%lwt () = copy_stats(~stat, dst_path);
  Lwt.return();
};

let create_dir = path => {
  let path = Fpath.to_string(path);
  try%lwt (Lwt_unix.mkdir(path, 0o755)) {
  | [@implicit_arity] Unix.Unix_error(Unix.EEXIST, _, _) => Lwt.return()
  };
};