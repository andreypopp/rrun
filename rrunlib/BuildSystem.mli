(** This implements build system *)

val resolve : ?base:Source.t -> string -> Source.t
(** Resolve source against base. *)

val build : cfg:Config.t -> Fpath.t -> Fpath.t Lwt.t
(** Build program and return a path of the compiled executable. *)
