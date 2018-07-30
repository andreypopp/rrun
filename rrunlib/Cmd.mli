(**
 * Commands.
 *
 * Command is a tool and a list of arguments.
 *)

type t

val v : string -> t
(** Produce a command supplying a tool. *)

val ( % ) : t -> string -> t
(** Add a new argument to the command. *)

val p : Fpath.t -> string
(** Convert path to a string suitable to use with (%). *)

val add_arg : string -> t -> t
(**
 * Add a new argument to the command.
 *
 * Same as (%) but with a flipped argument order.
 * Added for convenience usage with (|>).
 *)

val add_args : string list -> t -> t
(**
 * Add a list of arguments to the command.
 *
 * it is convenient to use with (|>).
 *)

val tool_and_args : t -> string * string list

val tool_and_line : t -> string * string array
(**
 * Get a tuple of a tool and a list of argv suitable to be passed into
 * Lwt_process or Unix family of functions.
 *)

val tool : t -> string

val args : t -> string list

val pp : Format.formatter -> t -> unit

val show : t -> string

val to_string : t -> string

val equal : t -> t -> bool

val compare : t -> t -> int
