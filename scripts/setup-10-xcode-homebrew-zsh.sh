# Xcode CLT, Homebrew, Oh My Zsh, and custom zsh symlinks (sourced by ../setup.sh).

print_section "Starting macOS bootstrap setup"

print_step "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  print_step "Xcode Command Line Tools not found; launching installer"
  xcode-select --install
  echo "Complete Xcode Command Line Tools installation, then re-run setup.sh."
  exit 1
fi

print_step "Installing Homebrew"
ensure_brew_shellenv
if command -v brew >/dev/null 2>&1; then
  print_step "Homebrew already installed; skipping install"
else
  run_or_die "Homebrew install" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

ensure_brew_shellenv

print_step "Installing oh-my-zsh"
OMZ_DIR="${HOME}/.oh-my-zsh"
if [ -d "$OMZ_DIR" ]; then
  print_step "Oh My Zsh already present at ${OMZ_DIR}; skipping install"
else
  # --unattended: no exec zsh at the end (would abort the rest of setup.sh), no chsh/sudo
  # prompts, no .zshrc overwrite prompt — safe for CI and non-interactive runs.
  run_or_die "oh-my-zsh install" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

print_step "Linking custom zsh config files"
REPO_ROOT="$(pwd)"
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_aliases.zsh" ~/.oh-my-zsh/custom/custom_aliases.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_env_variables.zsh" ~/.oh-my-zsh/custom/custom_env_variables.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_functions.zsh" ~/.oh-my-zsh/custom/custom_functions.zsh
ln -sf "${REPO_ROOT}/configs/oh-my-zsh/custom_startup.zsh" ~/.oh-my-zsh/custom/custom_startup.zsh
