# Shared helpers for macOS bootstrap (sourced by ../setup.sh and ../doctor.sh).
# Expects SETUP_ROOT (repo root) to be set by the caller.

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

# Oh My Zsh custom files that live in configs/oh-my-zsh/ and are symlinked into ~/.oh-my-zsh/custom/.
OMZ_CUSTOM_FILES="custom_aliases.zsh custom_env_variables.zsh custom_functions.zsh"

# Symlink ~/.zshrc and the Oh My Zsh custom files to this repo.
# A regular ~/.zshrc (not a symlink) is moved to ~/.zshrc.backup-<timestamp> first.
link_shell_configs() {
  local f backup
  if [ -e "${HOME}/.zshrc" ] && [ ! -L "${HOME}/.zshrc" ]; then
    backup="${HOME}/.zshrc.backup-$(date +%Y%m%d%H%M%S)"
    mv "${HOME}/.zshrc" "${backup}" || return 1
    echo "Moved existing ~/.zshrc to ${backup}"
  fi
  ln -sfn "${SETUP_ROOT}/configs/.zshrc-custom" "${HOME}/.zshrc" || return 1
  mkdir -p "${HOME}/.oh-my-zsh/custom" || return 1
  for f in ${OMZ_CUSTOM_FILES}; do
    ln -sfn "${SETUP_ROOT}/configs/oh-my-zsh/${f}" "${HOME}/.oh-my-zsh/custom/${f}" || return 1
  done
}

# Safe Chain (https://github.com/AikidoSec/safe-chain): pinned release + checksum verify.
# Trust model: we only execute the installer after SHA256 matches the value recorded below
# for that GitHub release asset. Bump SAFE_CHAIN_VERSION and re-fetch checksum when upgrading.
# Upgrade path
# 1. Set SAFE_CHAIN_VERSION to the new tag (e.g. 1.5.28).
# 2. Download install-safe-chain.sh for that release and run shasum -a 256 on it.
# 3. Update the default sha=... in install_safe_chain (here, in setup-00-lib.sh) (or pass SAFE_CHAIN_SHA256 when running the script).
install_safe_chain() {
  local version sha url tmpdir script actual
  version="${SAFE_CHAIN_VERSION:-1.5.27}"
  sha="${SAFE_CHAIN_SHA256:-600ebddcb3aaf1fd53653a8d7985df44528722c0f5ee7eb9fff86f26a1a4e5a8}"
  url="https://github.com/AikidoSec/safe-chain/releases/download/${version}/install-safe-chain.sh"
  tmpdir="$(mktemp -d)"
  script="${tmpdir}/install-safe-chain.sh"
  trap 'rm -rf "${tmpdir}"' EXIT
  curl -fsSL "${url}" -o "${script}"
  actual="$(shasum -a 256 "${script}" | awk '{print $1}')"
  if [ "${actual}" != "${sha}" ]; then
    die "Safe Chain installer checksum mismatch (expected ${sha}, got ${actual}). Refusing to run."
  fi
  # SAFE_CHAIN_VERSION pins the release the installer downloads (otherwise it fetches the latest).
  run_or_die "Safe Chain install" env SAFE_CHAIN_VERSION="${version}" sh "${script}"
  trap - EXIT
  rm -rf "${tmpdir}"
}
