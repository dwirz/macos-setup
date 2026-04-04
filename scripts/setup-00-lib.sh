# Shared helpers for macOS bootstrap (sourced by ../setup.sh).

print_section() {
  echo ""
  echo "=============================================================="
  echo "$1"
  echo "=============================================================="
}

print_step() {
  echo "-> $1"
}

die() {
  echo "Error: $*" >&2
  exit 1
}

run_or_die() {
  local desc="$1"
  shift
  if ! "$@"; then
    die "${desc} failed"
  fi
}

# Put Homebrew on PATH (Apple Silicon and Intel). Safe to call before or after install.
ensure_brew_shellenv() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}
