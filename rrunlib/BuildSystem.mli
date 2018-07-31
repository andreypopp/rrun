(** This implements build system *)

val resolve : string -> Fpath.t -> Source.t

val build : cfg:Config.t -> Fpath.t -> Fpath.t Lwt.t
(** Build program and return a path of the compiled executable. *)
