# rrun

rrun stands for "Reason Run" and is an opinionated runtime for Reason (and
OCaml).

## Installation (not implemented yet)

Install rrun via npm:

```shell
% npm install -g rrun
```

## Usage

Run Reason or OCaml programs with:

```shell
% rrun ./app.re
% rrun ./app.ml
```

You can specify dependencies between modules via `[%import "..."]` syntax:

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

### TODO

- [ ] Sandboxed execution
- [ ] Support interfaces

- [x] Build Reason code
- [x] Build OCaml code
- [x] Support `[%import "./relative/path.ml"]` dependencies
- [x] Support `[%import "https://secure/url.ml"]` dependencies
