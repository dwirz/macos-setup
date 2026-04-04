#!/usr/bin/env bash
set -euo pipefail

# Install a user LaunchAgent that runs `tmbliss service` once daily (default: lunch).
# Requires: tmbliss (brew), jq (brew). See https://github.com/Reeywhaar/tmbliss

ensure_brew_shellenv() {
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

die() {
  echo "Error: $*" >&2
  exit 1
}

validate_time() {
  local t="$1" h m
  [[ "$t" =~ ^([0-9]+):([0-9]+)$ ]] || return 1
  h="${BASH_REMATCH[1]}"
  m="${BASH_REMATCH[2]}"
  if ! ((10#$h >= 0 && 10#$h <= 23)); then return 1; fi
  if ! ((10#$m >= 0 && 10#$m <= 59)); then return 1; fi
  HOUR=$((10#$h))
  MINUTE=$((10#$m))
  return 0
}

ensure_brew_shellenv

if ! command -v tmbliss >/dev/null 2>&1; then
  echo "Skipping tmbliss schedule: tmbliss not found on PATH."
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Skipping tmbliss schedule: jq not found on PATH (needed to write config)."
  exit 0
fi

read -r -p "Schedule daily tmbliss (Time Machine exclusions for dev trees) [Y/n]: " SCHEDULE_INPUT
case "${SCHEDULE_INPUT:-Y}" in
  [nN]|[nN][oO])
    echo "Skipping tmbliss LaunchAgent."
    exit 0
    ;;
esac

DEFAULT_ROOT="${HOME}/projects"
read -r -p "Root directory to scan [${DEFAULT_ROOT}]: " ROOT_INPUT
SCAN_ROOT="${ROOT_INPUT:-$DEFAULT_ROOT}"
SCAN_ROOT="${SCAN_ROOT/#\~/${HOME}}"
if [ ! -d "$SCAN_ROOT" ]; then
  read -r -p "Directory does not exist. Create it? [Y/n]: " MKDIR_INPUT
  case "${MKDIR_INPUT:-Y}" in
    [nN]|[nN][oO]) die "Cannot schedule tmbliss without an existing path." ;;
  esac
  mkdir -p "$SCAN_ROOT"
fi

DEFAULT_TIME="12:30"
read -r -p "Daily run time 24h (HH:MM) [${DEFAULT_TIME}]: " TIME_INPUT
TIME_RAW="${TIME_INPUT:-$DEFAULT_TIME}"
if ! validate_time "$TIME_RAW"; then
  die "Invalid time (use HH:MM, e.g. 12:30)."
fi

TMBLISS_BIN="$(command -v tmbliss)"
CONFIG_DIR="${HOME}/.config/tmbliss"
CONFIG_FILE="${CONFIG_DIR}/tmbliss.json"
PLIST_LABEL="com.tmbliss.daily"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_LABEL}.plist"
LOG_DIR="${HOME}/Library/Logs"
STDOUT_LOG="${LOG_DIR}/tmbliss.log"
STDERR_LOG="${LOG_DIR}/tmbliss.err.log"

mkdir -p "$CONFIG_DIR" "$LOG_DIR"

jq -n \
  --arg p "$SCAN_ROOT" \
  '{paths: [$p], allowlist_glob: ["**/.env", "**/.env.*"], dry_run: false, skip_errors: true}' \
  >"$CONFIG_FILE"

# Reload LaunchAgent if already loaded
if launchctl print "gui/$(id -u)/${PLIST_LABEL}" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || true
fi

cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${PLIST_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${TMBLISS_BIN}</string>
    <string>service</string>
    <string>--path</string>
    <string>${CONFIG_FILE}</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>${HOUR}</integer>
    <key>Minute</key>
    <integer>${MINUTE}</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>${STDOUT_LOG}</string>
  <key>StandardErrorPath</key>
  <string>${STDERR_LOG}</string>
</dict>
</plist>
EOF

chmod 644 "$PLIST_PATH"
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "tmbliss scheduled daily at ${TIME_RAW} for ${SCAN_ROOT}"
echo "Config: ${CONFIG_FILE}"
echo "Logs: ${STDOUT_LOG} / ${STDERR_LOG}"
