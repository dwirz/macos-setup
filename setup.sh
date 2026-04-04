#!/usr/bin/env bash
set -euo pipefail

# Fail fast: any command that returns non-zero stops the script (except where noted).
# Optional steps use explicit if/else; final zshrc source may be skipped if incompatible with bash.
#
# Orchestration only: numbered steps live in scripts/setup-NN-*.sh (run order matches filenames).

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SETUP_ROOT}/scripts/setup-00-lib.sh"
source "${SETUP_ROOT}/scripts/setup-10-xcode-homebrew-zsh.sh"
source "${SETUP_ROOT}/scripts/setup-20-brewfile-and-optional-tools.sh"
source "${SETUP_ROOT}/scripts/setup-22-netbird.sh"
source "${SETUP_ROOT}/scripts/setup-30-profile-prompts.sh"
source "${SETUP_ROOT}/scripts/setup-40-dev-profile-and-ssh.sh"
source "${SETUP_ROOT}/scripts/setup-45-wallpaper-lockscreen-screensaver.sh"
source "${SETUP_ROOT}/scripts/setup-50-safe-chain-and-app-configs.sh"
source "${SETUP_ROOT}/scripts/setup-60-macos-defaults-and-zshrc.sh"
source "${SETUP_ROOT}/scripts/setup-70-manual-steps.sh"
