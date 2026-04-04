#!/usr/bin/env bash

set -euo pipefail

# Install OpenScreen (Screen Recorder) via install-release (ir)
OPENSCREEN_REPO_URL="https://github.com/siddharthvaddem/openscreen"
IR_BIN="$(command -v ir || true)"

if [ -z "$IR_BIN" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user -U install-release
    IR_BIN="$(python3 -m site --user-base)/bin/ir"
  else
    echo "Skipping OpenScreen install: python3 not found (required to install 'ir')."
  fi
fi

if [ -n "$IR_BIN" ] && [ -x "$IR_BIN" ]; then
  "$IR_BIN" get "$OPENSCREEN_REPO_URL"
else
  echo "Skipping OpenScreen install: 'ir' is not available."
fi
