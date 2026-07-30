#!/usr/bin/env bash
# See scripts/perf-ocaml.sh --help for usage.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPAMROOT="${OPAMROOT:-/lm/users/arul/.opam}"
OCAML_SWITCH="${OCAML_SWITCH:-5.5.0}"
BINARY="${ROOT}/ocaml/_build/default/bin/main.exe"
DEFAULT_DATA="${ROOT}/perf/ocaml-main.data"

die() {
  echo "perf-ocaml: $*" >&2
  exit 1
}

need_perf() {
  command -v perf >/dev/null 2>&1 || die "perf not found; install perf (e.g. linux-tools) and ensure it is on PATH"
}

build_demo() {
  echo "==> Building OCaml demo (make ocaml)" >&2
  make -C "${ROOT}" ocaml
}

ensure_binary() {
  [[ -x "${BINARY}" ]] || build_demo
  [[ -x "${BINARY}" ]] || die "binary not found at ${BINARY} (try: $0 record --build)"
}

usage() {
  cat <<EOF
Record or report perf profiles for the OCaml kron demo (main.exe).

Usage:
  scripts/perf-ocaml.sh record [--build] [--data FILE] [--] [perf record args...]
  scripts/perf-ocaml.sh report [--data FILE] [--] [perf report args...]

Examples:
  scripts/perf-ocaml.sh record
  make perf-ocaml
  scripts/perf-ocaml.sh report -- --sort=symbol

Environment:
  OPAMROOT, OCAML_SWITCH  opam settings (same defaults as Makefile)
  PERF_DATA               default output file for record / input for report

Commands:
  record   Run perf record on main.exe (default).
  report   Run perf report on saved data.

Options (record):
  --build      Build before recording (default: build only if binary is missing).
  --no-build   Skip build even if binary is missing.
  --data FILE  perf.data output path (default: ${DEFAULT_DATA})

Options (report):
  --data FILE  perf.data input path (default: ${DEFAULT_DATA})

Extra perf flags go after --, e.g.:
  $0 report -- --sort=symbol --no-children
EOF
}

parse_data_flag() {
  DATA="${PERF_DATA:-${DEFAULT_DATA}}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --data)
        shift
        [[ $# -gt 0 ]] || die "--data requires an argument"
        DATA="$1"
        ;;
      --data=*)
        DATA="${1#--data=}"
        ;;
      *)
        break
        ;;
    esac
    shift
  done
  PERF_REST=("$@")
}

cmd_record() {
  local do_build=auto
  parse_data_flag "$@"
  set -- "${PERF_REST[@]}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build)
        do_build=yes
        ;;
      --no-build)
        do_build=no
        ;;
      --)
        shift
        break
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        break
        ;;
    esac
    shift
  done

  need_perf
  case "${do_build}" in
    yes) build_demo ;;
    no) ;;
    auto) [[ -x "${BINARY}" ]] || build_demo ;;
  esac
  ensure_binary

  mkdir -p "$(dirname "${DATA}")"
  echo "==> perf record -g --call-graph dwarf -o ${DATA} -- ${BINARY}" >&2
  perf record -g --call-graph dwarf -o "${DATA}" -- "${BINARY}" "$@"

  cat >&2 <<EOF

==> Done. Inspect with:
    $0 report --data ${DATA}
    $0 report --data ${DATA} -- --sort=symbol
    perf report -i ${DATA} --no-children

Look for futhark_* (generated C) vs caml* / thuli (OCaml runtime and glue).
EOF
}

cmd_report() {
  parse_data_flag "$@"
  set -- "${PERF_REST[@]}"

  if [[ "${1:-}" == "--" ]]; then
    shift
  fi

  need_perf
  [[ -f "${DATA}" ]] || die "perf data not found: ${DATA} (run: $0 record)"

  echo "==> perf report -i ${DATA} $*" >&2
  perf report -i "${DATA}" "$@"
}

main() {
  local cmd="${1:-record}"
  case "${cmd}" in
    record)
      shift
      cmd_record "$@"
      ;;
    report)
      shift
      cmd_report "$@"
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      die "unknown command: ${cmd} (try --help)"
      ;;
  esac
}

main "$@"
