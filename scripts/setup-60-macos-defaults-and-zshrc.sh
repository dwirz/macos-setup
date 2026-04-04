# macOS defaults (sudo) and shell reload (sourced by ../setup.sh).

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

print_step "Validating ~/.zshrc in zsh"
# Oh My Zsh requires zsh ($ZSH_VERSION). setup.sh runs bash with set -u, so we must not
# source ~/.zshrc here — that triggers "unbound variable ZSH_VERSION".
if [ -f "${HOME}/.zshrc" ] && command -v zsh >/dev/null 2>&1; then
  zsh -c 'source ~/.zshrc' || echo "Note: ~/.zshrc returned non-zero in zsh; fix errors above."
elif [ ! -f "${HOME}/.zshrc" ]; then
  echo "No ~/.zshrc found."
else
  echo "Skipping ~/.zshrc check: zsh not on PATH."
fi
