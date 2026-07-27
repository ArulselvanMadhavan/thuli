# thuli

Futhark library project for n-dimensional tensor abstractions.

## Project layout

```
futhark.pkg
lib/github.com/ArulselvanMadhavan/thuli/   # library modules
programs/                                     # entry points
tests/                                        # futhark test suites
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
```

Docker:

```bash
make docker-build
make docker-run
make docker-test
```

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

### Verification checklist

1. `make check FILE=<each edited .fut file>`
2. `make check-changed`
3. `make test`
4. If Docker files changed: `make docker-build`
