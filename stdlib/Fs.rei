/* File System Manipulation */
let exists: Path.t => Repromise.t(bool);
let mustExist: Path.t => Repromise.t(Path.t);
let create: string => Repromise.t(unit);
let list: Path.t => Repromise.t(list(string));
let move: (Path.t, Path.t) => Repromise.t(unit);
let delete: string => Repromise.t(unit);
let stat: string => Repromise.t(Unix.stats);
let truncate: (int, Unix.file_descr) => Repromise.t(unit);
let isExecutable: Path.t => Repromise.t(bool);

/* Links */
let link: (string, string) => Repromise.t(unit);
let symlink: (string, string) => Repromise.t(unit);
let unlink: string => Repromise.t(unit);
let symlinkStat: Path.t => Repromise.t(Unix.stats);

/* Read */
let read: Path.t => Repromise.t(string);
let readLines: Path.t => Repromise.t(list(string));

/* Write */
let write: Path.t => Repromise.t(unit);
let writeLines: Path.t => Repromise.t(unit);