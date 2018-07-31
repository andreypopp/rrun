val stat : Fpath.t -> Unix.stats Lwt.t
(** stat *)

val read_file : Fpath.t -> string Lwt.t
(** Read file *)

val copy_file :
     ?before:(   Lwt_io.output Lwt_io.channel
              -> Lwt_io.input Lwt_io.channel
              -> unit Lwt.t)
  -> src_path:Fpath.t
  -> Fpath.t
  -> unit Lwt.t
(** Copy file *)

val create_dir : Fpath.t -> unit Lwt.t
(** Create directory *)
