/** This implements build system */;

/** Resolve source against base. */
let resolve: (~base: Source.t=?, string) => Source.t;

/** Build program and return a path of the compiled executable. */
let build: (~cfg: Config.t, Fpath.t) => Lwt.t(Fpath.t);
