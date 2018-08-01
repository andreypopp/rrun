# rrun

**WIP: DO NOT USE, this piece of software isn't ready for general consumption,
some things are not implemented, some things are not working properly.**

[![Build Status](https://travis-ci.com/andreypopp/rrun.svg?branch=master)](https://travis-ci.com/andreypopp/rrun)

rrun allows to seamlessly run [Reason][]/[OCaml][] code with native speed.

## Motivation

rrun aims to implement the following workflow for engineering software with
Reason/OCaml language:

- Start writing code by opening a plain `*.re` or `*.ml` file
  - ... with autocomplete and real time error reporting available
  - ... having a good set of standard libraries for interacting with a system
  - ... reusing 3rd party code from a local file system or from the network
- Code can be run with a single command invocation `rrun ./myapp.re`
  - ... which builds the code and caches the result
  - ... and sandboxes (configurable) execution by preventing it from
    reading/writing to disk or accessing network

## Installation (not implemented yet)

Install rrun via npm:

```shell
% npm install -g rrun
```

## Usage

### Running Code

Run Reason/OCaml code with:

```shell
% rrun ./app.re
% rrun ./app.ml
```

rrun uses `ocamlopt` to compile sources and then caches compiled artifacts, on
second invocation there will be no recompilation.

### Dependencies

You can specify dependencies between modules with `[%import "..."]` syntax:

```
module Url = [%import "./Url.re"]
module Chalk = [%import "https://example.com/Chalk.re"]

let url = Url.make("http://example.com");
print_endline(Chalk.red(Url.show(url)));
```

### IDE support

There's `rrun edit` command which will run your configured editor (via
`$EDITOR`) in a properly configured environment:

```
% rrun edit ./app.re
```

### Sandboxed Execution

TODO

## Internals

TODO

## Development

### Workflow

```
% npm install -g esy
% git clone https://github.com/andreypopp/rrun.git
% cd rrun
% esy install
% esy build
% esy "$EDITOR"
```

### Roadmap

- [ ] Sandboxed execution
- [ ] Support interfaces

- [x] Build Reason code
- [x] Build OCaml code
- [x] Support `[%import "./relative/path.ml"]` dependencies
- [x] Support `[%import "https://secure/url.ml"]` dependencies

[OCaml]: https://ocaml.org
[Reason]: https://reasonml.github.io
