type dep = {
  id: string,
  spec: string,
  src: Source.t
};

type t = list(dep);

let sexp_of_t: t => Ppx_sexp_conv_lib.Sexp.t;

let t_of_sexp: Ppx_sexp_conv_lib.Sexp.t => t;

let of_file: Fpath.t => Lwt.t(t);
