type t = {
  store_path : Fpath.t;
}

let init ?store_path () =
  let store_path =
    match store_path with
    | Some store_path -> store_path
    | None -> Fpath.(System.homePath / ".rrun")
  in
  let%lwt () = Fs.create_dir store_path in
  Lwt.return {store_path}
