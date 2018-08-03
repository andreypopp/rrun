type t = {store_path: Fpath.t};

let init = (~store_path=?, ()) => {
  let store_path =
    switch (store_path) {
    | Some(store_path) => store_path
    | None => Fpath.(System.homePath / ".rrun")
    };

  let%lwt () = Fs.create_dir(store_path);
  Lwt.return({store_path: store_path});
};
