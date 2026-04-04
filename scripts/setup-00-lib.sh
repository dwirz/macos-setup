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

# Install a Mac App Store app via mas(1). Does not exit the setup script on failure
# (unsigned App Store session, network, region, or already installed edge cases).
mas_install_optional() {
  local id="$1"
  local name="${2:-$id}"
  if ! command -v mas >/dev/null 2>&1; then
    echo "Skipping mas install ${name} (${id}): mas not on PATH."
    return 0
  fi
  if mas install "$id"; then
    echo "Installed ${name} (${id}) via mas."
  else
    echo "Note: mas install ${name} (${id}) failed — open the App Store app and sign in if needed, then run: mas install ${id}"
  fi
  return 0
}
