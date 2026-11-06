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

# Get (free) or install a Mac App Store app via `mas get` (mas 7+; asks for sudo itself).
# Does not exit the setup script on failure
# (unsigned App Store session, network, region, or already installed edge cases).
mas_install_optional() {
  local id="$1"
  local name="${2:-$id}"
  if ! command -v mas >/dev/null 2>&1; then
    echo "Skipping mas get ${name} (${id}): mas not on PATH."
    return 0
  fi
  if mas get "$id"; then
    echo "Installed ${name} (${id}) via mas."
  else
    echo "Note: mas get ${name} (${id}) failed — open the App Store app and sign in if needed, then run: mas get ${id}"
  fi
  return 0
}

# Directory containing powerlevel10k.zsh-theme from Homebrew (after `brew install powerlevel10k`).
# Checks the formula keg and HOMEBREW_PREFIX/share (linked path). Prints one line: absolute path.
powerlevel10k_brew_share_dir() {
  ensure_brew_shellenv
  local keg hp
  keg="$(brew --prefix powerlevel10k 2>/dev/null)" || true
  hp="$(brew --prefix 2>/dev/null)" || true
  if [ -n "${keg}" ] && [ -f "${keg}/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    printf '%s\n' "${keg}/share/powerlevel10k"
    return 0
  fi
  if [ -n "${hp}" ] && [ -f "${hp}/share/powerlevel10k/powerlevel10k.zsh-theme" ]; then
    printf '%s\n' "${hp}/share/powerlevel10k"
    return 0
  fi
  return 1
}

# Symlink Homebrew's Powerlevel10k tree into Oh My Zsh custom themes (what ~/.zshrc sources).
link_powerlevel10k_homebrew_to_omz() {
  local src
  src="$(powerlevel10k_brew_share_dir)" || true
  if [ -z "${src}" ]; then
    echo "Error: Powerlevel10k is not available from Homebrew." >&2
    echo "  Expected: \$(brew --prefix powerlevel10k)/share/powerlevel10k/powerlevel10k.zsh-theme" >&2
    echo "  Or: \$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >&2
    echo "  Install: brew install powerlevel10k  (or ensure brew bundle completed successfully)" >&2
    return 1
  fi
  mkdir -p "${HOME}/.oh-my-zsh/custom/themes"
  ln -sfn "${src}" "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
  return 0
}
