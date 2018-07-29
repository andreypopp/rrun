# rrun

rrun stands for "Reason Run" and is an opinionated runtime for Reason (and
OCaml).

## Installation (not implemented yet)

Install rrun via npm:

```shell
% npm install -g rrun
```

## Usage (not implemented yet)

Given a file with valid Reason syntax one can execute it with:

```shell
% rrun ./app.re
```

or with OCaml syntax:

```shell
% rrun ./app.ml
```

Another option is to add shebang line which mentiones `rrun`:

```reason
#!/usr/bin/env rrun

print_endline("Hello, World!");
```

or with OCaml syntax:

```ocaml
#!/usr/bin/env rrun

let () =
  print_endline "Hello, World!"
```

## Features

### Dependency Management

rrun has its own dependency management mechanism inspired by [deno][].

The special syntax `[%import SPEC]` is used to reference other modules, where
`SPEC` can be either a relative path or an URL pointing to an `https:` resource.
Examples:

- ```reason
  module Url = [%import "./Url.re"]
  ```

- ```reason
  module Url = [%import "https://example.com/url@0.1.2/Url.re"]
  ```

### Sandboxed Execution

TODO

## Internals

TODO
