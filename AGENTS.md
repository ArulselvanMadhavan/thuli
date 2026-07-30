# thuli

Futhark library project for n-dimensional tensor abstractions.

## Project layout

```
futhark.pkg
lib/github.com/ArulselvanMadhavan/thuli/   # library modules
programs/                                     # entry points
tests/                                        # futhark test suites
ocaml/                                        # OCaml wrapper (ctypes + dune)
```

Library files live under `lib/<package-path>/`, matching `futhark.pkg`:

```
package github.com/ArulselvanMadhavan/thuli
```

## Commands

```bash
make compile       # compile programs/main.fut to bin/main
make run           # run compiled entry point
make test          # run futhark test suites
make check-changed # type-check all changed .fut files
make clean         # remove build artifacts
make kron-lib      # compile programs/kron.fut to bin/libkron.{c,h}
make ocaml         # build OCaml library (requires opam env; see below)
make ocaml-run     # build and run ocaml/bin/main.exe demo
make perf-ocaml    # perf record of OCaml demo (see docs/perf.md)
```

Docker:

```bash
make docker-build
make docker-run
make docker-test
```

## OCaml environment

Use this opam root and switch for all OCaml/dune work in this repo:

```bash
export OPAMROOT="/lm/users/arul/.opam"
eval "$(OPAMROOT="$OPAMROOT" opam env --switch=5.5.0)"
```

Makefile targets (`make ocaml`, `make ocaml-run`) set these automatically via:

- `OPAMROOT ?= /lm/users/arul/.opam`
- `OCAML_SWITCH ?= 5.5.0`

### First-time setup

Create the switch and install build deps if missing:

```bash
export OPAMROOT="/lm/users/arul/.opam"
opam switch create 5.5.0 ocaml-base-compiler.5.5.0
eval "$(OPAMROOT="$OPAMROOT" opam env --switch=5.5.0)"
opam install dune ctypes ctypes-foreign
```

### Before running OCaml commands manually

Always instantiate the opam environment in the current shell before `dune`, `ocaml`, or `opam` commands outside `make`:

```bash
export OPAMROOT="/lm/users/arul/.opam"
eval "$(OPAMROOT="$OPAMROOT" opam env --switch=5.5.0)"
cd ocaml && dune build
```

Do not assume a global opam switch; use `OPAMROOT` and switch `5.5.0`.

### OCaml layout

```
ocaml/
  dune-project
  thuli/           # thuli library (bindings.ml, kron.ml, thuli_tensor.ml)
  bin/main.ml      # demo executable
```

Futhark generates `bin/libkron.c`; `make kron-lib` copies it to `ocaml/thuli/kron.c` for dune foreign stubs.

## Rules for agents

### After editing any `.fut` file

Type-check the file you changed:

```bash
make check FILE=path/to/file.fut
```

Before finishing a task, check all changed Futhark files:

```bash
make check-changed
```

Examples:

```bash
make check FILE=lib/github.com/ArulselvanMadhavan/thuli/tensor.fut
make check FILE=programs/main.fut
make check FILE=tests/main_test.fut
```

### After editing OCaml files (`.ml`, `.mli`, `dune`, `dune-project`)

Instantiate opam env, then build:

```bash
export OPAMROOT="/lm/users/arul/.opam"
eval "$(OPAMROOT="$OPAMROOT" opam env --switch=5.5.0)"
make ocaml
```

Or from repo root (Makefile applies opam env):

```bash
make ocaml
make ocaml-run   # build + run demo when behavior changed
```

### Imports

From `programs/` or `tests/`:

```futhark
import "../lib/github.com/ArulselvanMadhavan/thuli/tensor"
```

From another file in the same package:

```futhark
import "tensor"
```

### Conventions

- Put reusable library code in `lib/github.com/ArulselvanMadhavan/thuli/`.
- Put `entry` points in `programs/`.
- Put test blocks in `tests/`.
- Do not commit generated artifacts (`bin/`, `*.c`, `*.h`).
- Use `/bin/docker` in Make targets (not bare `docker`).
- Compiled binaries read from stdin on a TTY; `make run` redirects with `< /dev/null`.

### Git commits

- Do not add `Co-authored-by:`, `Made-with: Cursor`, or other attribution trailers.
- Use plain `git commit -m "..."` only (no `--trailer`).
- Always commit via the repo hook: `git -c core.hooksPath=.githooks commit -m "..."`.
  The hook strips any `Co-authored-by: Cursor` trailer injected by tooling.

### Verification checklist

1. `make check FILE=<each edited .fut file>`
2. `make check-changed`
3. `make test`
4. If OCaml files changed: `make ocaml` (and `make ocaml-run` if runtime behavior changed)
5. If Docker files changed: `make docker-build`
