# API Surface Draft

This document is meant to spec out the API surface of the "standard" lib that we 
are adding to RRun. This directory for right now will containe a few interface 
files for each initial module I plan on implementing. Once the interface for 
these is approved the implementation will begin and so will testing.

## `Cmd`

#### Description:

Execute and produce commands.

#### API:

```re
type t;
let empty: t;

/* Converters */
let ofString: string => t;
let toString: t => string;
let ofList: list(string) => t;
let toList: t => list(string);
let path: Path.t => t;

/* Predicates */
let isEmpty: t => bool;
let equal: (t, t) => bool;
let compare: (t, t) => int;

/* Cmd Operators */
let addArg: (t, string) => t;
let addArgs: (t, list(string)) => t;

/* Cmd Accessors */
let getTool: t => string;
let getArgs: t => list(string)
let getToolAndArgs: t => (string, list(string));
```

---

## `JSON`

#### Description:

Json Encoding and Decoding

#### API:

```re
type t;
exception ParsingError(string);

/* Write Json */
let toString: t => string;
let toChannel: (t, out_channel) => unit;
let toFile: (t, string) => unit;

/* Read Json */
let fromString: string => t;
let fromChannel: in_channel => t;
let fromFile: string => t;

/* Json combinators */
let field: (string, t) => 'a;
let toBool: t => bool;
let toString: t => string;
let toFloat: t => float;
let toInt: t => int;
let toTuple2: t => ('a, 'b);
let toTuple3: t => ('a, 'b, 'c);
let toTuple4: t => ('a, 'b, 'c, 'd);
let toList: t => list('a);
let toArray: t => array('a);
let toOption: t => option('a);
let either: (t, t =>'a, t => 'a) => 'a;
let oneOf: (t, list(t => 'a)) => 'a;
```

---

## `Fs`

#### Description:

File System access and manipulation

#### API:

```re
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
```

---

## `Path`

#### Description:

Utilities for interacting with file and directory paths

#### API:

```rei
type t;
type ext = string;
type pathRecord = {
  dir: option(string),
  root: option(string),
  base: option(string),
  name: option(string),
  ext: option(string),
};

/* Path symbols */
let dirSep: string;
let delimeter: string;

/* Path converters */
let toString: t => string;
let toList: t => list(string);
let ofString: string => t;
let ofRecord: pathRecord => t;
let ofList: list(string) => t;

/* Accessors */
let filename: t => string;
let basename: t => string;
let dirname: t => string;
let extname: (~multi: bool=?, t) => string;
let parent: t => t;
let toDirPath: t => t;

/* Extension operators */
let addExt: (ext, t) => t;
let removeExt: (ext, t) => t;
let setExt: (ext, t) => t;
let splitExt: (~multi: bool=?, t) => (ext, t);

/* Predicates */
let isAbsolute: t => bool;
let isRelative: t => bool;
let isRoot: t => bool;
let isCurrentDir: t => bool;
let isParentDir: (~prefix: bool=?, t) => bool;
let isDotFile: t => bool;
let isDirPath: t => bool;
let isFilePath: t => bool;
let hasExt: (ext, t) => bool;
let existsExt: (~multi: bool=?, t) => bool;

/* Path Builders */
let removeEmptyPath: t => t;
let addToPath: (t, string) => t;
let append: (t, t) => t;
let join: list(string) => t;

/* Path Normalizers */
let normalize: t => t;
let relative: (t, t) => t;
let resolve: list(string) => t;
let parse: t => pathRecord;
```

---
