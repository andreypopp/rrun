type dep = {id: string; spec: string; src: Source.t}

type t = dep list

val sexp_of_t : t -> Ppx_sexp_conv_lib.Sexp.t
val t_of_sexp : Ppx_sexp_conv_lib.Sexp.t -> t

val of_file : Fpath.t -> t Lwt.t
