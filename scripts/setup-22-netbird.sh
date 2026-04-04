# NetBird VPN daemon (sourced by ../setup.sh after Brewfile installs netbird-ui).

NETBIRD_MANAGEMENT_URL="${NETBIRD_MANAGEMENT_URL:-https://netbird.smarties.app}"

print_step "NetBird: install and start system service"
ensure_brew_shellenv
if ! command -v netbird >/dev/null 2>&1; then
  echo "Skipping NetBird service: netbird CLI not on PATH (install netbird-ui from the Brewfile)."
else
  if sudo netbird service install --management-url "${NETBIRD_MANAGEMENT_URL}" && sudo netbird service start; then
    echo "NetBird service installed and started (management URL: ${NETBIRD_MANAGEMENT_URL})."
  else
    echo "Note: NetBird service step failed or was cancelled. When ready, run:"
    echo "  sudo netbird service install --management-url ${NETBIRD_MANAGEMENT_URL}"
    echo "  sudo netbird service start"
  fi
fi
