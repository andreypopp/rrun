(*
 * Tool and a reversed list of args.
 *
 * We store args reversed so we allow an efficient append.
 *
 * XXX: It is important we do List.rev at the boundaries so we don't get a
 * reversed argument order.
 *)

open Ppx_compare_lib.Builtin

type t = string * string list [@@deriving compare]

let equal a b = compare a b = 0

let v tool = (tool, [])

let p = Fpath.to_string

let add_arg arg (tool, args) =
  let args = arg :: args in
  (tool, args)

let add_args nargs (tool, args) =
  let args =
    let f args arg = arg :: args in
    ListLabels.fold_left ~f ~init:args nargs
  in
  (tool, args)

let ( % ) (tool, args) arg =
  let args = arg :: args in
  (tool, args)

let tool_and_args (tool, args) =
  let args = List.rev args in
  (tool, args)

let tool_and_line (tool, args) =
  let args = List.rev args in
  (tool, Array.of_list (tool :: args))

let tool (tool, _args) = tool

let args (_tool, args) = List.rev args

let to_string (tool, args) =
  let tool = Filename.quote tool in
  let args = List.rev args in
  StringLabels.concat ~sep:" " (tool :: args)

let show = to_string

let pp ppf (tool, args) =
  match args with
  | [] -> Fmt.(pf ppf "%s" tool)
  | args ->
      let args = List.rev args in
      let line = List.map Filename.quote (tool :: args) in
      Fmt.(pf ppf "@[<h>%a@]" (list ~sep:sp string) line)
