# rrun

**WIP: DO NOT USE**

rrun allows to seamlessly run [Reason][]/[OCaml][] code with native speed.

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

### TODO

- [ ] Sandboxed execution
- [ ] Support interfaces

- [x] Build Reason code
- [x] Build OCaml code
- [x] Support `[%import "./relative/path.ml"]` dependencies
- [x] Support `[%import "https://secure/url.ml"]` dependencies

[OCaml]: https://ocaml.org
[Reason]: https://reasonml.github.io
