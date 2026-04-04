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

print_step "Sourcing ~/.zshrc for current shell"
# shellcheck disable=SC1090
source ~/.zshrc || echo "Note: ~/.zshrc returned non-zero under bash; new zsh sessions will still load it."
