open Ppxlib;
open Rrun;

let name = "import";

module Deps = {
  module N = {
    let name = "deps";
  };

  module V = DepsMeta;

  module NV = Driver.Create_file_property(N, V);
  include NV;
};

let dependencies = ref([]);

let expand = (~loc, ~path as _, spec: string) => {
  let ident = {
    let src = {
      let base =
        try (
          {
            let data = Sys.getenv("RRUN_BASE");
            data |> Sexplib.Sexp.of_string |> Source.t_of_sexp;
          }
        ) {
        | Not_found =>
          let cwd = Sys.getcwd();
          Source.Path(Fpath.(v(cwd) /\/ v(loc.loc_start.pos_fname)));
        };

      BuildSystem.resolve(~base, spec);
    };

    let id = Source.id(src);
    let ident = id |> Longident.parse |> Loc.make(~loc);
    dependencies := [{DepsMeta.id, spec, src}, ...dependencies^];
    Deps.set(dependencies^);
    ident;
  };

  Ast_builder.Default.pmod_ident(~loc, ident);
};

let () = {
  let ext = {
    let pat1 = Ast_pattern.(estring(__));
    let pat2 = {
      open Ast_pattern;
      let f = (_, v) => v;
      map2(
        ~f,
        pexp_attributes(
          many(
            attribute(
              string("reason.raw_literal"),
              single_expr_payload(estring(__)),
            ),
          ),
          estring(__),
        ),
      );
    };

    Extension.declare(
      name,
      Extension.Context.module_expr,
      Ast_pattern.(single_expr_payload(pat1 ||| pat2)),
      expand,
    );
  };

  Driver.register_transformation(name, ~extensions=[ext]);
};

let () = Driver.standalone();
