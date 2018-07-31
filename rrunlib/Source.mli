type t =
  | Path of Path.t
  | Https of Uri.t

val id : t -> string
val sexp_of_t : t -> Ppx_sexp_conv_lib.Sexp.t
val t_of_sexp : Ppx_sexp_conv_lib.Sexp.t -> t
