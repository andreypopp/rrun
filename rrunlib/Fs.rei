/** Check if file or dir exists. */
let exists: Fpath.t => Lwt.t(bool);

/** stat */
let stat: Fpath.t => Lwt.t(Unix.stats);

/** Read file */
let read_file: Fpath.t => Lwt.t(string);

/** Copy file */
let copy_file:
  (
    ~before: (Lwt_io.channel(Lwt_io.output), Lwt_io.channel(Lwt_io.input)) =>
             Lwt.t(unit)
               =?,
    ~src_path: Fpath.t,
    Fpath.t
  ) =>
  Lwt.t(unit);

/** Create directory */
let create_dir: Fpath.t => Lwt.t(unit);