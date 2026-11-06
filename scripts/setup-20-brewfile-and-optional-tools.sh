# Brewfile, U.S. with German Umlauts, tmbliss (sourced by ../setup.sh).
# fzf shell integration is loaded by configs/.zshrc-custom (`source <(fzf --zsh)`); its
# install script is not run because it would append to ~/.zshrc, which is a symlink into this repo.

print_step "Installing Brewfile packages and apps"
# Non-fatal: one failing or disabled cask must not stop the rest of the setup.
if ! brew bundle --file="${SETUP_ROOT}/Brewfile"; then
  echo "Note: brew bundle reported failures (see above). Continuing; re-run later with:"
  echo "  brew bundle --file=${SETUP_ROOT}/Brewfile"
fi

print_step "Mac App Store apps (mas; optional, non-fatal if not signed in)"
ensure_brew_shellenv
mas_install_optional 506189836 "Harvest"

print_step "Installing U.S. with German Umlauts keyboard layout"
US_UMLAUTS_SCRIPT="${SETUP_ROOT}/scripts/install-us-with-german-umlauts.sh"
if [ -f "$US_UMLAUTS_SCRIPT" ]; then
  chmod +x "$US_UMLAUTS_SCRIPT"
  "$US_UMLAUTS_SCRIPT" || echo "Note: keyboard layout install failed; continuing setup."
else
  echo "Skipping keyboard layout: $US_UMLAUTS_SCRIPT not found."
fi

print_step "Optional: tmbliss daily schedule (Time Machine exclusions)"
ensure_brew_shellenv
TMBLISS_LAUNCHAGENT_SCRIPT="${SETUP_ROOT}/scripts/setup-tmbliss-launchagent.sh"
if [ -f "$TMBLISS_LAUNCHAGENT_SCRIPT" ]; then
  chmod +x "$TMBLISS_LAUNCHAGENT_SCRIPT"
  "$TMBLISS_LAUNCHAGENT_SCRIPT" || echo "Note: tmbliss schedule step exited non-zero; continuing setup."
else
  echo "Skipping tmbliss schedule: $TMBLISS_LAUNCHAGENT_SCRIPT not found."
fi
