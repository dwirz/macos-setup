#!/usr/bin/env bash
set -euo pipefail

# Fail fast: any command that returns non-zero stops the script (except where noted).
# Optional steps use explicit if/else; final zshrc source may be skipped if incompatible with bash.

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

print_section "Starting macOS bootstrap setup"

print_step "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  print_step "Xcode Command Line Tools not found; launching installer"
  xcode-select --install
  echo "Complete Xcode Command Line Tools installation, then re-run setup.sh."
  exit 1
fi

print_step "Installing Homebrew"
run_or_die "Homebrew install" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ensure_brew_shellenv

print_step "Installing oh-my-zsh"
run_or_die "oh-my-zsh install" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

print_step "Linking custom zsh config files"
REPO_ROOT="$(pwd)"
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_aliases.zsh" ~/.oh-my-zsh/custom/custom_aliases.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_env_variables.zsh" ~/.oh-my-zsh/custom/custom_env_variables.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_functions.zsh" ~/.oh-my-zsh/custom/custom_functions.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_startup.zsh" ~/.oh-my-zsh/custom/custom_startup.zsh

print_step "Installing Brewfile packages and apps"
run_or_die "brew bundle" brew bundle

print_step "Installing OpenScreen helper tool"
OPENSCREEN_SETUP_SCRIPT="./scripts/install-openscreen.sh"
if [ -f "$OPENSCREEN_SETUP_SCRIPT" ]; then
  chmod +x "$OPENSCREEN_SETUP_SCRIPT"
  run_or_die "OpenScreen install" "$OPENSCREEN_SETUP_SCRIPT"
else
  echo "Skipping OpenScreen install: $OPENSCREEN_SETUP_SCRIPT not found."
fi

print_step "Configuring fzf shell integration"
if FZF_PREFIX="$(brew --prefix fzf 2>/dev/null)" && [ -n "$FZF_PREFIX" ] && [ -x "$FZF_PREFIX/install" ]; then
  run_or_die "fzf install script" "$FZF_PREFIX/install" --all
else
  echo "Skipping fzf integration: fzf not installed or install script missing."
fi

print_step "Collecting profile values (name/email/domain)"
read -r -p "Full name [Your Name]: " NAME_INPUT
NAME="${NAME_INPUT:-Your Name}"
read -r -p "Email [you@your-domain.com]: " EMAIL_INPUT
EMAIL="${EMAIL_INPUT:-you@your-domain.com}"
read -r -p "Website/Domain [your-domain.com]: " DOMAIN_INPUT
DOMAIN="${DOMAIN_INPUT:-your-domain.com}"
read -r -p "Computer name (menu bar / sharing) [${NAME}]: " COMPUTER_NAME_INPUT
COMPUTER_NAME="${COMPUTER_NAME_INPUT:-$NAME}"

print_step "Applying Node, npm, and Git profile setup"
DEV_PROFILE_SETUP_SCRIPT="./scripts/setup-dev-profile.sh"
if [ -f "$DEV_PROFILE_SETUP_SCRIPT" ]; then
  chmod +x "$DEV_PROFILE_SETUP_SCRIPT"
  run_or_die "dev profile setup" "$DEV_PROFILE_SETUP_SCRIPT" "$NAME" "$EMAIL" "$DOMAIN"
else
  echo "Skipping dev profile setup: $DEV_PROFILE_SETUP_SCRIPT not found."
fi

print_step "Running interactive SSH key setup"
SSH_SETUP_SCRIPT="./scripts/setup-ssh.sh"
if [ -f "$SSH_SETUP_SCRIPT" ]; then
  chmod +x "$SSH_SETUP_SCRIPT"
  run_or_die "SSH setup" "$SSH_SETUP_SCRIPT" "$EMAIL"
else
  echo "Skipping SSH setup: $SSH_SETUP_SCRIPT not found."
fi

print_step "Installing Safe Chain"
install_safe_chain

print_step "Copying Cursor profile"
mkdir -p ~/Library/Application\ Support/Cursor/User/profiles/
run_or_die "Cursor profile copy" cp -r ./configs/cursor.code-profile ~/Library/Application\ Support/Cursor/User/profiles/

print_step "Copying Warp terminal theme"
mkdir -p ~/.warp/themes/
run_or_die "Warp theme copy" cp -r ./configs/warp-terminal-theme.yaml ~/.warp/themes/warp-terminal-theme.yaml

print_step "Copying Powerlevel10k theme"
run_or_die "p10k copy" cp -r ./configs/.p10k.zsh ~/.p10k.zsh

print_step "Applying macOS defaults (requires sudo)"
MACOS_SETTINGS_SCRIPT="./scripts/macos-settings.sh"
if [ -f "$MACOS_SETTINGS_SCRIPT" ]; then
  chmod +x "$MACOS_SETTINGS_SCRIPT"
  if [ -n "${MACOS_SETTINGS_SECTIONS:-}" ]; then
    run_or_die "macOS settings" sudo "$MACOS_SETTINGS_SCRIPT" --sections="${MACOS_SETTINGS_SECTIONS}" "$COMPUTER_NAME"
  elif [ "${MACOS_SETTINGS_ALL:-}" = "1" ]; then
    run_or_die "macOS settings" sudo "$MACOS_SETTINGS_SCRIPT" --all "$COMPUTER_NAME"
  else
    run_or_die "macOS settings" sudo "$MACOS_SETTINGS_SCRIPT" "$COMPUTER_NAME"
  fi
else
  echo "Skipping macOS settings: $MACOS_SETTINGS_SCRIPT not found."
fi

print_step "Sourcing ~/.zshrc for current shell"
# shellcheck disable=SC1090
source ~/.zshrc || echo "Note: ~/.zshrc returned non-zero under bash; new zsh sessions will still load it."

print_section "Setup complete"

echo ""
print_section "Manual steps remaining"
print_step "Screen Recording permissions"
echo "   - Open: System Settings > Privacy & Security > Screen Recording"
echo "   - Enable for Raycast and browsers you use."
echo ""
print_step "Night Shift"
echo "   - Open: System Settings > Displays > Night Shift"
echo "   - Configure schedule and color temperature."
echo ""
print_step "Raycast Clipboard History"
echo "   - Open Raycast Preferences > Extensions"
echo "   - Enable 'Clipboard History'"
echo "   - Optional: assign hotkey/alias"
