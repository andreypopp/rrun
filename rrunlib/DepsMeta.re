open Sexplib.Conv;

[@deriving sexp]
type t = list(dep)
and dep = {
  id: string,
  spec: string,
  src: Source.t,
};

let of_file = path => {
  let%lwt data = Fs.read_file(path);
  if (String.length(data) == 0) {
    Lwt.return([]);
  } else {
    switch (Sexplib.Sexp.of_string(data)) {
    | Sexplib.Sexp.List([Sexplib.Sexp.Atom("deps"), deps]) =>
      let items = t_of_sexp(deps);
      Lwt.return(items);
    | _ => raise(Invalid_argument("invalid dependency format"))
    };
  };
};