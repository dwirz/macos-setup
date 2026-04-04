#!/usr/bin/env bash

set -euo pipefail

# Install OpenScreen (Screen Recorder) via install-release (ir).
# Uses a dedicated venv — never `pip install` into Homebrew/system Python (PEP 668
# "externally-managed-environment").
OPENSCREEN_REPO_URL="https://github.com/siddharthvaddem/openscreen"
VENV_DIR="${HOME}/.local/share/macos-setup/venv-install-release"

# install-release → python-magic needs Homebrew’s libmagic (brew "libmagic" in Brewfile).
if command -v brew >/dev/null 2>&1; then
  _libmagic_prefix="$(brew --prefix libmagic 2>/dev/null || true)"
  if [ -n "${_libmagic_prefix}" ] && [ -d "${_libmagic_prefix}/lib" ]; then
    export DYLD_LIBRARY_PATH="${_libmagic_prefix}/lib${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}"
  fi
fi

IR_BIN=""
if command -v ir >/dev/null 2>&1; then
  IR_BIN="$(command -v ir)"
elif [ -x "${VENV_DIR}/bin/ir" ]; then
  IR_BIN="${VENV_DIR}/bin/ir"
fi

if [ -z "${IR_BIN}" ] && command -v python3 >/dev/null 2>&1; then
  echo "Installing install-release (ir) into ${VENV_DIR} (isolated venv; avoids PEP 668)..."
  mkdir -p "$(dirname "${VENV_DIR}")"
  if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
  fi
  "${VENV_DIR}/bin/python" -m pip install -U pip
  "${VENV_DIR}/bin/python" -m pip install -U install-release
  IR_BIN="${VENV_DIR}/bin/ir"
elif [ -z "${IR_BIN}" ]; then
  echo "Skipping OpenScreen install: python3 not found (needed for install-release)."
fi

if [ -n "${IR_BIN}" ] && [ -x "${IR_BIN}" ]; then
  "${IR_BIN}" get "${OPENSCREEN_REPO_URL}"
else
  echo "Skipping OpenScreen install: 'ir' is not available after install-release setup."
fi
