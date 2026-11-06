# Safe Chain and app/editor theme copies (sourced by ../setup.sh).
# The Cursor profile (configs/cursor.code-profile) is imported by hand; see README manual steps.

# Safe Chain (https://github.com/AikidoSec/safe-chain): pinned release + checksum verify.
# Trust model: we only execute the installer after SHA256 matches the value recorded below
# for that GitHub release asset. Bump SAFE_CHAIN_VERSION and re-fetch checksum when upgrading.
# Upgrade path
# 1. Set SAFE_CHAIN_VERSION to the new tag (e.g. 1.5.28).
# 2. Download install-safe-chain.sh for that release and run shasum -a 256 on it.
# 3. Update the default sha=... in install_safe_chain (or pass SAFE_CHAIN_SHA256 when running the script).
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

print_step "Installing Safe Chain"
install_safe_chain

print_step "Copying Warp terminal theme"
mkdir -p ~/.warp/themes/
run_or_die "Warp theme copy" cp "${SETUP_ROOT}/configs/warp-terminal-theme.yaml" ~/.warp/themes/warp-terminal-theme.yaml

print_step "Powerlevel10k: prompt config and Homebrew → Oh My Zsh theme symlink"
ensure_brew_shellenv
if [ -f "${HOME}/.p10k.zsh" ] && ! cmp -s "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"; then
  P10K_BACKUP="${HOME}/.p10k.zsh.backup-$(date +%Y%m%d%H%M%S)"
  cp "${HOME}/.p10k.zsh" "${P10K_BACKUP}"
  echo "Backed up existing ~/.p10k.zsh to ${P10K_BACKUP}"
fi
run_or_die "p10k user config copy" cp "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"
run_or_die "Powerlevel10k (brew) → ~/.oh-my-zsh/custom/themes/powerlevel10k" link_powerlevel10k_homebrew_to_omz
