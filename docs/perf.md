# Performance profiling and improvement plan

This document records how to profile the OCaml/Futhark `kron`/`kpow` path and
where time is spent, based on `perf` data collected on the project demo.

## Collecting profiles

Use the helper script (no application instrumentation required):

```bash
./scripts/perf-ocaml.sh record --build
./scripts/perf-ocaml.sh report -- --sort=symbol --no-children
./scripts/perf-ocaml.sh report          # interactive TUI
```

Or via Make:

```bash
make perf-ocaml
```

Output defaults to `perf/ocaml-main.data` (gitignored). Override with
`PERF_DATA` or `--data FILE`.

Requirements:

- `perf` on `PATH` (often the `linux-tools` package on Linux)
- Built demo binary: `ocaml/_build/default/bin/main.exe` (`make ocaml`)

For meaningful compute samples, temporarily increase the workload in
`ocaml/bin/main.ml` (e.g. `kpow pauli_x 14` produces a 16384×16384 tensor).
Restore small demo values before committing.

## Profile snapshot (kpow 14, Pauli-X)

Collected with:

```bash
./scripts/perf-ocaml.sh record --no-build --data perf/ocaml-main.data
```

Run characteristics:

- ~19k samples, ~15B cycles, ~5.5s user time
- Final tensor: shape `[16384; 16384]`, 268435456 complex elements (f32 re/im)

### Time breakdown

| Share | Symbol / area | What it is |
|------:|---------------|------------|
| **91.7%** | `futhark_entry_kron_entry` | Futhark `QT.kron` (generated C) |
| ↳ ~19% | `smod64` | 64-bit `%` in index arithmetic |
| ↳ ~9% | `sdiv64` | 64-bit `/` in index arithmetic |
| ↳ ~3% | `add64` | Index adds |
| ↳ ~3% | `__memset_avx512_*` | Output buffer zero/init inside entry |
| **5.0%** | `__memmove_avx512_*` | Host copies; mostly `futhark_values_f32_1d` |
| **~1%** | `futhark_new_f32_1d` | Host→Futhark array upload |
| **~0%** | `caml_*`, `ctypes_*` | OCaml runtime and FFI glue |

**Conclusion:** OCaml/ctypes overhead is negligible at this scale. Optimise
Futhark compute first, then host↔Futhark copies.

### Hot Futhark source

The entry calls `MkQuantumTensor` `kron`, which tabulates every output element
with full N-D index decode and re-encode:

```futhark
tabulate (s1 * s2) (\flat_out_idx ->
  let k_idx = unflat_offset out_shape flat_out_idx
  in N.mul (get A (map2 (/) k_idx b_shape))
           (get B (map2 (%) k_idx b_shape)))
```

Per output element this runs:

1. `unflat_offset` — O(rank) div/mod steps (`tensor.fut`)
2. `map2 (/)` and `map2 (%)` — another div/mod per dimension
3. Two `get` calls — flat offset + array load
4. Complex multiply

For rank 2 and hundreds of millions of elements, integer division dominates.

## Improvement plan (priority order)

### 1. Rewrite `kron` index logic (lib `quantum_tensor.fut`) — **~92%**

Target: `kron` in `lib/github.com/ArulselvanMadhavan/thuli/quantum_tensor.fut`
and helpers `unflat_offset` / `flat_offset` in `tensor.fut`.

Actions:

- Avoid materialising `k_idx : [rank]i64` per element; fuse index arithmetic
  into a single flat-index formula.
- For rank 2, specialise (e.g. derive row/col from one flat index with one
  div/mod pair).
- For rank `r`, precompute stride vectors **once** outside `tabulate`, then
  use multiply-add inside the loop.
- Prefer `map` over `tabulate` where possible so the multicore/GPU backends
  can parallelise.

Expected impact: largest win; directly reduces `smod64`/`sdiv64` samples.

### 2. Use a parallel Futhark backend — **multiplier on (1)**

Target: `Makefile` `kron-lib` rule (`futhark c --library` today).

Actions:

- Try `futhark multicore c --library` for CPU parallelism.
- For GPU: `futhark cuda --library` or `futhark opencl --library`; same C API,
  but link CUDA/OpenCL runtimes and expect host↔device copy costs.

Expected impact: near-linear speedup on parallelisable loops once index work
is cheap.

### 3. Binary exponentiation for `kpow` (`ocaml/thuli/thuli_tensor.ml`) — **algorithmic**

Target: `kpow` linear loop calling `kron` `(n-1)` times.

Actions:

- Replace with binary exponentiation (O(log n) `kron` calls).
- Optionally move `kpow` into Futhark as an entry when exponent is runtime.

Expected impact: fewer intermediate kronecks; large win for high exponents
before the final huge multiply.

### 4. Reduce FFI copies (`ocaml/thuli/kron.ml`, `programs/kron.fut`) — **~6%**

Target: `futhark_new_f32_1d`, `futhark_values_f32_1d`, `read_f32_1d`,
`futhark_project_kron_out_*`.

Actions:

- Keep intermediate tensors on the Futhark heap across `kpow` iterations;
  copy out only once at the end.
- Investigate `futhark_new_raw_f32_1d` / `futhark_values_raw_f32_1d` for
  tighter Bigarray integration.
- Simplify the entry return type if possible (avoid opaque tuple projection).

Expected impact: modest at huge single-kron sizes; more important when many
small/medium kronecks run in sequence.

### 5. Do not prioritise

| Area | Reason |
|------|--------|
| `kron.ml` ctypes bindings | ~0% in profile |
| `with_parts`, `allocate`, `check` | Noise |
| `make_complex`, list→Bigarray helpers | One-time setup |

## Futhark runtime profiling (optional)

The generated C API also exposes:

- `futhark_context_config_set_profiling`
- `futhark_context_report`

These report time inside the Futhark runtime (per kernel/event), complementary
to `perf` which sees the whole process. Can be wired into `kron.ml` behind an
environment flag without changing default behaviour.

## Re-checking after changes

```bash
make ocaml
./scripts/perf-ocaml.sh record --build
./scripts/perf-ocaml.sh report -- --sort=symbol --no-children
```

Compare `futhark_entry_kron_entry` share and `smod64`/`sdiv64` before/after.
Run `make test` and `make ocaml-run` to confirm correctness.
