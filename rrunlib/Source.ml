open Sexplib.Conv

type t =
  | Path of Path.t
  | Https of string
  [@@deriving sexp]

let safe_string spec =
  let out = Buffer.create (String.length spec) in
  String.iter
    (function
      | '.' -> Buffer.add_string out "S_DT_"
      | '/' -> Buffer.add_string out "S_SL_"
      | '@' -> Buffer.add_string out "S_AT_"
      | '_' -> Buffer.add_string out "S_UN_"
      | '-' -> Buffer.add_string out "S_DH_"
      | ' ' -> Buffer.add_string out "S_SP_"
      | ':' -> Buffer.add_string out "S_CL_"
      | ';' -> Buffer.add_string out "S_SC_"
      | c -> Buffer.add_char out c)
    spec;
  Buffer.contents out

let id = function
  | Path path -> "U" ^ (safe_string (Path.to_string path))
  | Https url -> "M" ^ (safe_string url)
