open Sexplib.Conv

type t = dep list [@@deriving sexp]

and dep = {id: string; spec: string; src: Source.t}

let of_file path =
  let%lwt data = Fs.read_file path in
  if String.length data = 0 then Lwt.return []
  else
    match Sexplib.Sexp.of_string data with
    | Sexplib.Sexp.(List [Atom "deps"; deps]) ->
        let items = t_of_sexp deps in
        Lwt.return items
    | _ -> raise (Invalid_argument "invalid dependency format")

