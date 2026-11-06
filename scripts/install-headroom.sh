#!/usr/bin/env bash

set -euo pipefail

# Install Headroom (headroom-ai[proxy]) via pipx — not Homebrew.
# Safe-local defaults are applied at runtime by the headroom:cursor shell function.

ensure_brew_shellenv() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_brew_shellenv

if ! command -v pipx >/dev/null 2>&1; then
  echo "Skipping Headroom install: pipx not on PATH (brew install pipx)."
  exit 0
fi

PYTHON313="$(brew --prefix python@3.13 2>/dev/null)/bin/python3.13"
if [ ! -x "${PYTHON313}" ]; then
  echo "Skipping Headroom install: python@3.13 not found (brew install python@3.13)."
  exit 0
fi

export PATH="${HOME}/.local/bin:${PATH}"

if command -v headroom >/dev/null 2>&1; then
  echo "Headroom already installed: $(headroom --version)"
  exit 0
fi

echo "Installing headroom-ai[proxy] via pipx (python ${PYTHON313})..."
pipx install --python "${PYTHON313}" "headroom-ai[proxy]"
pipx ensurepath

if command -v headroom >/dev/null 2>&1; then
  headroom --version
else
  echo "Headroom install finished but 'headroom' is not on PATH."
  echo "Open a new shell or add ~/.local/bin to PATH, then run: headroom --version"
fi
