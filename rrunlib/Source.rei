type t =
  | Path(Path.t)
  | Https(Uri.t);

let id: t => string;

let sexp_of_t: t => Ppx_sexp_conv_lib.Sexp.t;

let t_of_sexp: Ppx_sexp_conv_lib.Sexp.t => t;
