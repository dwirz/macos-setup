# Chrome & Arc: Web Store extension manifests (External Extensions JSON).
# Sourced by ../setup.sh. See scripts/install-chrome-extensions.sh.

if [[ "${SKIP_BROWSER_EXTENSIONS:-0}" == "1" ]]; then
  echo "Skipping browser extension manifests (SKIP_BROWSER_EXTENSIONS=1)."
else
  print_step "Registering Web Store extensions for Google Chrome and Arc"
  EXT_SCRIPT="${SETUP_ROOT}/scripts/install-chrome-extensions.sh"
  if [[ -f "$EXT_SCRIPT" ]]; then
    run_or_die "browser extension manifests" bash "$EXT_SCRIPT"
  else
    echo "Note: ${EXT_SCRIPT} not found; skipping."
  fi
fi
