open Ppxlib

let name = "import"

module Deps = struct
  module N = struct
    let name = "deps"
  end

  module V = struct
    type t = (string * string) list

    module S = Sexplib0.Sexp

    let sexp_of_t items =
      let f (id, spec) = S.List [S.Atom id; S.Atom spec] in
      let items = List.map f items in
      S.List items

    let t_of_sexp _ = [("s", "some")]
  end

  module NV = Driver.Create_file_property (N) (V)
  include NV
end

let dependencies = ref []

let expand ~loc ~path:_ (spec: string) =
  let ident =
    let filename =
      let basePath = Fpath.(parent (v loc.loc_start.pos_fname)) in
      Rrun.BuildSystem.resolve spec basePath
    in
    let id = Rrun.BuildSystem.makeId filename in
    let ident = id |> Longident.parse |> Loc.make ~loc in
    dependencies := (id, filename) :: !dependencies ;
    Deps.set !dependencies ;
    ident
  in
  Ast_builder.Default.pmod_ident ~loc ident

let () =
  let ext =
    Extension.declare name Extension.Context.module_expr
      Ast_pattern.(single_expr_payload (estring __))
      expand
  in
  Driver.register_transformation name ~extensions:[ext]

let () = Driver.standalone ()
