/**
 * Commands.
 *
 * Command is a tool and a list of arguments.
 */;

 type t;

 /** Produce a command supplying a tool. */ 
 let v: string => t;
 
 /** Add a new argument to the command. */ 
 let (%): (t, string) => t;
 
 /** Convert path to a string suitable to use with (%). */
 let p: Fpath.t => string;
 
 /**
  * Add a new argument to the command.
  *
  * Same as (%) but with a flipped argument order.
  * Added for convenience usage with (|>).
  */
 let add_arg: (string, t) => t;
 
 /**
  * Add a list of arguments to the command.
  *
  * it is convenient to use with (|>).
  */
 let add_args: (list(string), t) => t;
 
 let tool_and_args: t => (string, list(string));
 
 /**
  * Get a tuple of a tool and a list of argv suitable to be passed into
  * Lwt_process or Unix family of functions.
  */
 let tool_and_line: t => (string, array(string));
 
 let tool: t => string;
 
 let args: t => list(string);
 
 let pp: (Format.formatter, t) => unit;
 
 let show: t => string;
 
 let to_string: t => string;
 
 let equal: (t, t) => bool;
 
 let compare: (t, t) => int;
 