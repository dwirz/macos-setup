# Desktop wallpaper, lock screen image, and photo screensaver (sourced by ../setup.sh).

print_step "Wallpaper, lock screen, and screensaver"

APPLY_SCRIPT="${SETUP_ROOT}/scripts/apply-wallpaper-lockscreen-screensaver.sh"
chmod +x "$APPLY_SCRIPT" 2>/dev/null || true
if [ -x "$APPLY_SCRIPT" ]; then
  "$APPLY_SCRIPT" "$SETUP_ROOT"
else
  echo "Skipping: ${APPLY_SCRIPT} not executable."
fi
