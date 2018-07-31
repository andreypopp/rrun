let homePath =
  match Sys.getenv_opt "HOME" with
  | Some path -> Fpath.v path
  | None -> Fpath.v (Unix.(getpwnam "username").pw_dir)

let currentPath =
  Fpath.(v (Sys.getcwd ()))
