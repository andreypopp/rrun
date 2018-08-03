include Fpath;

let t_of_sexp = sexp => {
  let v = Sexplib.Conv.string_of_sexp(sexp);
  Fpath.v(v);
};

let sexp_of_t = v => {
  let v = to_string(v);
  Sexplib.Conv.sexp_of_string(v);
};
