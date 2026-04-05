# Safe Chain and app/editor theme copies (sourced by ../setup.sh).

# Safe Chain (https://github.com/AikidoSec/safe-chain): pinned release + checksum verify.
# Trust model: we only execute the installer after SHA256 matches the value recorded below
# for that GitHub release asset. Bump SAFE_CHAIN_VERSION and re-fetch checksum when upgrading.
# Upgrade path
# 1. Set SAFE_CHAIN_VERSION to the new tag (e.g. 1.4.8).
# 2. Download install-safe-chain.sh for that release and run shasum -a 256 on it.
# 3. Update the default sha=... in install_safe_chain (or pass SAFE_CHAIN_SHA256 when running the script).
install_safe_chain() {
  local version sha url tmpdir script actual
  version="${SAFE_CHAIN_VERSION:-1.4.7}"
  sha="${SAFE_CHAIN_SHA256:-54c750232d149106ecf4f5f28fee82ba49d2428f1e411e0ed961c0263ae19eaf}"
  url="https://github.com/AikidoSec/safe-chain/releases/download/${version}/install-safe-chain.sh"
  tmpdir="$(mktemp -d)"
  script="${tmpdir}/install-safe-chain.sh"
  trap 'rm -rf "${tmpdir}"' EXIT
  curl -fsSL "${url}" -o "${script}"
  actual="$(shasum -a 256 "${script}" | awk '{print $1}')"
  if [ "${actual}" != "${sha}" ]; then
    die "Safe Chain installer checksum mismatch (expected ${sha}, got ${actual}). Refusing to run."
  fi
  run_or_die "Safe Chain install" sh "${script}"
  trap - EXIT
  rm -rf "${tmpdir}"
}

print_step "Installing Safe Chain"
install_safe_chain

print_step "Copying Cursor profile"
mkdir -p ~/Library/Application\ Support/Cursor/User/profiles/
run_or_die "Cursor profile copy" cp -r ./configs/cursor.code-profile ~/Library/Application\ Support/Cursor/User/profiles/

print_step "Copying Warp terminal theme"
mkdir -p ~/.warp/themes/
run_or_die "Warp theme copy" cp -r ./configs/warp-terminal-theme.yaml ~/.warp/themes/warp-terminal-theme.yaml

print_step "Powerlevel10k: prompt config and Homebrew → Oh My Zsh theme symlink"
ensure_brew_shellenv
run_or_die "p10k user config copy" cp -r "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"
run_or_die "Powerlevel10k (brew) → ~/.oh-my-zsh/custom/themes/powerlevel10k" link_powerlevel10k_homebrew_to_omz
