let stat path =
  let path = Fpath.to_string path in
  Lwt_unix.stat path

let copy_stats ~stat path =
  let chown path uid gid =
    try%lwt Lwt_unix.chown path uid gid
    with Unix.Unix_error (Unix.EPERM, _, _) -> Lwt.return ()
  in
  let path = Fpath.to_string path in
  let%lwt () = Lwt_unix.utimes path stat.Unix.st_atime stat.Unix.st_mtime in
  let%lwt () = Lwt_unix.chmod path stat.Unix.st_perm in
  let%lwt () = chown path stat.Unix.st_uid stat.Unix.st_gid in
  Lwt.return ()

let read_file path =
  let path = Fpath.to_string path in
  Lwt_io.with_file ~mode:Lwt_io.Input path (fun ic -> Lwt_io.read ic)

let copy_file ?before ~src_path dst_path =
  let origPathS = Fpath.to_string src_path in
  let destPathS = Fpath.to_string dst_path in
  let chunkSize = 1024 * 1024 (* 1mb *) in
  let%lwt stat = Lwt_unix.stat origPathS in
  let copy ic oc =
    let buffer = Bytes.create chunkSize in
    let%lwt () =
      match before with Some before -> before oc ic | None -> Lwt.return ()
    in
    let rec loop () =
      match%lwt Lwt_io.read_into ic buffer 0 chunkSize with
      | 0 -> Lwt.return ()
      | bytesRead ->
          let%lwt () = Lwt_io.write_from_exactly oc buffer 0 bytesRead in
          loop ()
    in
    loop ()
  in
  let%lwt () =
    Lwt_io.with_file origPathS
      ~flags:Lwt_unix.[O_RDONLY]
      ~mode:Lwt_io.Input
      (fun ic ->
        Lwt_io.with_file ~mode:Lwt_io.Output
          ~flags:Lwt_unix.[O_WRONLY; O_CREAT; O_TRUNC]
          ~perm:stat.Unix.st_perm destPathS (copy ic) )
  in
  let%lwt () = copy_stats ~stat dst_path in
  Lwt.return ()

let create_dir path =
  let path = Fpath.to_string path in
  try%lwt Lwt_unix.mkdir path 0o755
  with Unix.Unix_error (Unix.EEXIST, _, _) -> Lwt.return ()
