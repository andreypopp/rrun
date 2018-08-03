type t = pri {store_path: Fpath.t};

let init: (~store_path: Fpath.t=?, unit) => Lwt.t(t);
