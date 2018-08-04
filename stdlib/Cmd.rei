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

/* Needs a Result module */
let resolve: (list(string), t) => t;