# API Surface Draft
This document is meant to spec out the API surface of the "standard" lib that we are adding to RRun.

## `Cmd`
#### Description: 
Command line Tools for building and executing CLI's

#### API:
```re

```
---

## `Fs`
#### Description: 
File System access and manipulation

#### API:
```re

```
---

## `Path`
#### Description: 
Utilities for interacting with file and directory paths

#### API:
```rei

let basename: (~ext: string=?, string) => string;

let delimeter: string;

let sep: string;

let dirname: string => string;

let extname: string => string;

type pathObject = {
  dir: option(string),
  root: option(string),
  base: option(string),
  name: option(string),
  ext: option(string)
};

let format: pathObject => string;

let isAbsolute: string => bool;

let join: list(string) => string;

let normalize: string => string;

let parse: string => pathObject;

let relative: (~from: string, ~_to: string) => string;

let relativeFilePath: (~from: string, ~_to: string) => string;

let resolve: list(string) => string;
```
---

## `Os`
#### Description: 
Unix/Windows system methods and properties

#### API:
```rei

```
---
