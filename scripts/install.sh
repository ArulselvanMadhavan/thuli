#!/usr/bin/env bash
# One-click setup for thuli on a new Linux machine (Futhark + OCaml/opam + smoke tests).
#
# Usage:
#   ./scripts/install.sh              # full install + verify
#   ./scripts/install.sh --help
#
# Environment (optional):
#   OPAMROOT          opam root (default: $HOME/.opam)
#   OCAML_SWITCH      opam switch (default: 5.5.0)
#   FUTHARK_VERSION   Futhark release (default: 0.26.4)
#   INSTALL_PREFIX    prefix for Futhark when not using sudo (default: $HOME/.local)
#   SUDO              sudo command (default: sudo); set empty to skip system packages

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FUTHARK_VERSION="${FUTHARK_VERSION:-0.26.4}"
OCAML_SWITCH="${OCAML_SWITCH:-5.5.0}"
OPAMROOT="${OPAMROOT:-${HOME}/.opam}"
INSTALL_PREFIX="${INSTALL_PREFIX:-${HOME}/.local}"
SUDO="${SUDO-sudo}"
VERIFY=1
SETUP_OCAML=1
CONFIGURE_GIT=1

log() { printf '==> %s\n' "$*"; }
die() { printf 'install: error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
One-click installer for thuli (Linux x86_64).

Usage: $0 [options]

Options:
  --no-verify     Skip make test / make ocaml-run after setup
  --no-ocaml      Skip opam switch and OCaml packages
  --no-git        Skip local git hooks configuration
  --help          Show this help

After install, load the dev environment in new shells:
  source scripts/env.sh

Or run make targets from the repo root; they read OPAMROOT / OCAML_SWITCH.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-verify) VERIFY=0 ;;
      --no-ocaml) SETUP_OCAML=0 ;;
      --no-git) CONFIGURE_GIT=0 ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1 (try --help)"
        ;;
    esac
    shift
  done
}

need_linux_x86_64() {
  [[ "$(uname -s)" == Linux ]] || die "this installer supports Linux only"
  case "$(uname -m)" in
    x86_64 | amd64) ;;
    *) die "this installer supports x86_64 only (found: $(uname -m))" ;;
  esac
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif [[ -n "${SUDO}" ]] && have_cmd "${SUDO}"; then
    "${SUDO}" "$@"
  else
    return 1
  fi
}

install_system_packages() {
  log "Installing system packages"
  if have_cmd apt-get; then
    run_as_root apt-get update
    run_as_root apt-get install -y --no-install-recommends \
      build-essential curl ca-certificates git m4 pkg-config xz-utils \
      libffi-dev libgmp-dev || die "apt install failed (try running as root or with sudo)"
  elif have_cmd dnf; then
    run_as_root dnf install -y \
      gcc gcc-c++ make curl ca-certificates git m4 pkgconfig xz \
      libffi-devel gmp-devel patch || die "dnf install failed"
  elif have_cmd yum; then
    run_as_root yum install -y \
      gcc gcc-c++ make curl ca-certificates git m4 pkgconfig xz \
      libffi-devel gmp-devel patch || die "yum install failed"
  else
    log "No supported package manager (apt/dnf/yum); skipping system packages"
    log "Ensure gcc, make, curl, git, m4, pkg-config, xz, libffi, gmp are installed"
  fi
}

install_futhark() {
  if have_cmd futhark; then
    log "Futhark already installed: $(futhark --version | head -1)"
    return
  fi

  local tarball="futhark-${FUTHARK_VERSION}-linux-x86_64.tar.xz"
  local url="https://github.com/diku-dk/futhark/releases/download/v${FUTHARK_VERSION}/${tarball}"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN

  log "Downloading Futhark ${FUTHARK_VERSION}"
  curl -fsSL "${url}" -o "${tmp}/${tarball}"
  tar -xJf "${tmp}/${tarball}" -C "${tmp}"

  if run_as_root install -m 755 \
    "${tmp}/futhark-${FUTHARK_VERSION}-linux-x86_64/bin/futhark" \
    /usr/local/bin/futhark; then
    log "Installed futhark to /usr/local/bin/futhark"
  else
    mkdir -p "${INSTALL_PREFIX}/bin"
    install -m 755 \
      "${tmp}/futhark-${FUTHARK_VERSION}-linux-x86_64/bin/futhark" \
      "${INSTALL_PREFIX}/bin/futhark"
    export PATH="${INSTALL_PREFIX}/bin:${PATH}"
    log "Installed futhark to ${INSTALL_PREFIX}/bin/futhark"
    log "Add to your shell profile: export PATH=\"${INSTALL_PREFIX}/bin:\$PATH\""
  fi

  have_cmd futhark || die "futhark not on PATH after install"
  log "Futhark version: $(futhark --version | head -1)"
}

install_opam() {
  if have_cmd opam; then
    log "opam already installed: $(opam --version)"
    return
  fi

  log "Installing opam via opam.ocaml.org/install.sh"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL https://opam.ocaml.org/install.sh -o "${tmp}"
  bash "${tmp}" --no-modify || die "opam install failed"
  rm -f "${tmp}"

  export PATH="${HOME}/.opam/default/bin:${HOME}/.local/bin:/usr/local/bin:${PATH}"
  have_cmd opam || die "opam not on PATH; open a new shell or add ~/.opam/default/bin to PATH"
  log "opam version: $(opam --version)"
}

setup_opam_switch() {
  log "Configuring opam (OPAMROOT=${OPAMROOT}, switch=${OCAML_SWITCH})"
  export OPAMROOT
  export PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"

  if ! opam root >/dev/null 2>&1; then
    opam init --bare --yes --no-setup
  fi

  if ! opam switch show 2>/dev/null | grep -qx "${OCAML_SWITCH}"; then
    if opam switch list --short 2>/dev/null | grep -qx "${OCAML_SWITCH}"; then
      opam switch set "${OCAML_SWITCH}"
    else
      opam switch create "${OCAML_SWITCH}" ocaml-base-compiler."${OCAML_SWITCH}" -y \
        || opam switch create "${OCAML_SWITCH}" ocaml-base-compiler."${OCAML_SWITCH}" -y --disable-sandboxing
    fi
  else
    opam switch set "${OCAML_SWITCH}"
  fi

  eval "$(OPAMROOT="${OPAMROOT}" opam env --switch="${OCAML_SWITCH}")"

  log "Installing OCaml packages: dune ctypes ctypes-foreign"
  opam install -y dune ctypes ctypes-foreign

  log "OCaml version: $(ocaml -version)"
}

write_env_sh() {
  log "Writing scripts/env.sh"
  cat >"${ROOT}/scripts/env.sh" <<EOF
# thuli development environment. Usage: source scripts/env.sh
export OPAMROOT="\${OPAMROOT:-${OPAMROOT}}"
export OCAML_SWITCH="\${OCAML_SWITCH:-${OCAML_SWITCH}}"
export PATH="\${HOME}/.local/bin:/usr/local/bin:\${PATH}"
if command -v opam >/dev/null 2>&1; then
  eval "\$(OPAMROOT="\${OPAMROOT}" opam env --switch="\${OCAML_SWITCH}")"
fi
EOF
}

configure_git_hooks() {
  [[ "${CONFIGURE_GIT}" -eq 1 ]] || return 0
  if ! have_cmd git; then
    log "git not found; skipping hooks configuration"
    return 0
  fi
  if [[ -d "${ROOT}/.git" && -x "${ROOT}/.githooks/prepare-commit-msg" ]]; then
    log "Configuring local git hooks (core.hooksPath=.githooks)"
    git -C "${ROOT}" config core.hooksPath .githooks
  fi
}

verify_install() {
  [[ "${VERIFY}" -eq 1 ]] || return 0
  log "Verifying Futhark tests (make test)"
  make -C "${ROOT}" test
  if [[ "${SETUP_OCAML}" -eq 1 ]]; then
    log "Verifying OCaml demo (make ocaml-run)"
    OPAMROOT="${OPAMROOT}" OCAML_SWITCH="${OCAML_SWITCH}" \
      make -C "${ROOT}" ocaml-run
  fi
}

print_done() {
  cat <<EOF

Install complete.

Next steps:
  cd ${ROOT}
  source scripts/env.sh
  make test
  make ocaml-run

Optional:
  make perf-ocaml     # requires perf (linux-tools)
  make docker-build   # container dev environment

Environment defaults:
  OPAMROOT=${OPAMROOT}
  OCAML_SWITCH=${OCAML_SWITCH}
EOF
}

main() {
  parse_args "$@"
  need_linux_x86_64
  cd "${ROOT}"

  install_system_packages
  install_futhark
  if [[ "${SETUP_OCAML}" -eq 1 ]]; then
    install_opam
    setup_opam_switch
  fi
  write_env_sh
  configure_git_hooks
  verify_install
  print_done
}

main "$@"
