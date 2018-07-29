let homePath = Fpath.(v "/Users/andreypopp")

let storePath = Fpath.(homePath / ".rrun")

let makeId spec =
  let len = String.length spec in
  let rec aux acc idx =
    if idx = len then acc |> List.rev |> String.concat ""
    else
      let chunk =
        match spec.[idx] with
        | '.' -> "S_DT_"
        | '/' -> "S_SL_"
        | '@' -> "S_AT_"
        | '_' -> "S_UN_"
        | '-' -> "S_DH_"
        | c -> String.make 1 c
      in
      aux (chunk :: acc) (idx + 1)
  in
  aux [] 0

let resolve spec basePath = Fpath.(basePath // v spec |> normalize |> to_string)

let build filename = Lwt.return filename
