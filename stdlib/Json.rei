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