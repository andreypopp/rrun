type t = private {
  store_path : Fpath.t;
}

val init : ?store_path:Fpath.t -> unit -> t Lwt.t
