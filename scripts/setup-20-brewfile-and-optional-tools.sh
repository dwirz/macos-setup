# Brewfile, OpenScreen, U.S. with German Umlauts, fzf, tmbliss (sourced by ../setup.sh).

print_step "Installing Brewfile packages and apps"
run_or_die "brew bundle" brew bundle

print_step "Mac App Store apps (mas; optional, non-fatal if not signed in)"
ensure_brew_shellenv
mas_install_optional 506189836 "Harvest"

print_step "Installing OpenScreen helper tool"
OPENSCREEN_SETUP_SCRIPT="./scripts/install-openscreen.sh"
if [ -f "$OPENSCREEN_SETUP_SCRIPT" ]; then
  chmod +x "$OPENSCREEN_SETUP_SCRIPT"
  run_or_die "OpenScreen install" "$OPENSCREEN_SETUP_SCRIPT"
else
  echo "Skipping OpenScreen install: $OPENSCREEN_SETUP_SCRIPT not found."
fi

print_step "Installing U.S. with German Umlauts keyboard layout"
US_UMLAUTS_SCRIPT="./scripts/install-us-with-german-umlauts.sh"
if [ -f "$US_UMLAUTS_SCRIPT" ]; then
  chmod +x "$US_UMLAUTS_SCRIPT"
  run_or_die "U.S. with German Umlauts" "$US_UMLAUTS_SCRIPT"
else
  echo "Skipping keyboard layout: $US_UMLAUTS_SCRIPT not found."
fi

print_step "Configuring fzf shell integration"
if FZF_PREFIX="$(brew --prefix fzf 2>/dev/null)" && [ -n "$FZF_PREFIX" ] && [ -x "$FZF_PREFIX/install" ]; then
  run_or_die "fzf install script" "$FZF_PREFIX/install" --all
else
  echo "Skipping fzf integration: fzf not installed or install script missing."
fi

print_step "Optional: tmbliss daily schedule (Time Machine exclusions)"
ensure_brew_shellenv
TMBLISS_LAUNCHAGENT_SCRIPT="./scripts/setup-tmbliss-launchagent.sh"
if [ -f "$TMBLISS_LAUNCHAGENT_SCRIPT" ]; then
  chmod +x "$TMBLISS_LAUNCHAGENT_SCRIPT"
  "$TMBLISS_LAUNCHAGENT_SCRIPT" || echo "Note: tmbliss schedule step exited non-zero; continuing setup."
else
  echo "Skipping tmbliss schedule: $TMBLISS_LAUNCHAGENT_SCRIPT not found."
fi
