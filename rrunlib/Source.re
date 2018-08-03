[@deriving sexp]
type t =
  | Path(Path.t)
  | Https(Uri.t);

let safe_string = spec => {
  let out = Buffer.create(String.length(spec));
  String.iter(
    fun
    | '.' => Buffer.add_string(out, "S_DT_")
    | '/' => Buffer.add_string(out, "S_SL_")
    | '@' => Buffer.add_string(out, "S_AT_")
    | '_' => Buffer.add_string(out, "S_UN_")
    | '-' => Buffer.add_string(out, "S_DH_")
    | ' ' => Buffer.add_string(out, "S_SP_")
    | ':' => Buffer.add_string(out, "S_CL_")
    | ';' => Buffer.add_string(out, "S_SC_")
    | c => Buffer.add_char(out, c),
    spec,
  );
  Buffer.contents(out);
};

let id =
  fun
  | Path(path) => "U" ++ safe_string(Path.to_string(path))
  | Https(url) => "M" ++ safe_string(Uri.to_string(url));
