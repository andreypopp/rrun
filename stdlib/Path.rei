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