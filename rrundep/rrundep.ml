open Ppxlib
open Rrun

let name = "import"

module Deps = struct
  module N = struct
    let name = "deps"
  end

  module V = DepsMeta

  module NV = Driver.Create_file_property (N) (V)
  include NV
end

let dependencies = ref []

let expand ~loc ~path:_ (spec: string) =
  let ident =
    let src =
      let fname =
        try Fpath.v (Sys.getenv "RRUN_FILENAME") with Not_found ->
          let cwd = Sys.getcwd () in
          Fpath.(v cwd // v loc.loc_start.pos_fname)
      in
      let basePath = Fpath.(parent fname) in
      BuildSystem.resolve spec basePath
    in
    let id = Source.id src in
    let ident = id |> Longident.parse |> Loc.make ~loc in
    dependencies := {DepsMeta. id; spec; src} :: !dependencies ;
    Deps.set !dependencies ;
    ident
  in
  Ast_builder.Default.pmod_ident ~loc ident

let () =
  let ext =
    let pat1 = Ast_pattern.(estring __) in
    let pat2 =
      let open Ast_pattern in
      let f _ v = v in
      map2 ~f
        (pexp_attributes
           (many
              (attribute
                 (string "reason.raw_literal")
                 (single_expr_payload (estring __))))
           (estring __))
    in
    Extension.declare name Extension.Context.module_expr
      Ast_pattern.(single_expr_payload (pat1 ||| pat2))
      expand
  in
  Driver.register_transformation name ~extensions:[ext]

let () = Driver.standalone ()
