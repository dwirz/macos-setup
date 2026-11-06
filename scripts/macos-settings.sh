#!/usr/bin/env bash
set -euo pipefail

# Computer name: optional last argument (used by the "sharing" section). Run
# `./macos-settings.sh --help` for options and section ids.
#
# Run as your user, not with sudo: `defaults write` changes the preferences of the user
# running it, so under sudo the settings would go to root. Only the system-level commands
# (computer name, removing apps) use sudo, and the script asks for it when needed.

usage() {
  cat <<'EOF'
Usage: ./macos-settings.sh [options] [COMPUTER_NAME]

Apply grouped macOS defaults. COMPUTER_NAME is used by the "sharing" section.

Options:
  --all, -a              Apply every section except remove_media (no prompts).
  --sections LIST        Comma-separated section ids (no prompts).
  --help, -h             Show this help.

Section ids:
  appearance    Screenshots JPG, dark mode, scroll bars
  dock          Dock layout, autohide, hot corners
  battery       Menu bar battery percentage
  siri          Siri off, Preview, notification gesture
  trackpad      Tap to click, speed, scroll
  keyboard      Smart punctuation off, Spotlight hotkey for Raycast
  finder        Downloads default, hidden files, trash, desktop
  sharing       Computer name (sudo)
  remove_media  Remove iMovie/GarageBand and Apple sound libraries (destructive, sudo;
                only when chosen at the prompt or named in --sections)

If stdin is not a terminal and you do not pass --sections or --all, the same
sections as --all are applied (avoids blocking on prompts).
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

ALL=false
SECTIONS_CLI=""
COMPUTER_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all | -a)
      ALL=true
      shift
      ;;
    --sections=*)
      SECTIONS_CLI="${1#*=}"
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1 (use --help)"
      ;;
    *)
      if [[ -n "$COMPUTER_NAME" ]]; then
        die "Unexpected extra argument: $1"
      fi
      COMPUTER_NAME="$1"
      shift
      ;;
  esac
done

if [[ -z "${COMPUTER_NAME}" ]]; then
  COMPUTER_NAME="$(scutil --get ComputerName 2>/dev/null || echo 'Mac')"
fi
LOCAL_HOST_NAME="$(echo "${COMPUTER_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | tr -s '-' | sed 's/^-//' | sed 's/-$//' | cut -c1-63)"
if [[ -z "${LOCAL_HOST_NAME}" ]]; then
  LOCAL_HOST_NAME="mac"
fi

section_label() {
  case "$1" in
    appearance) echo "Appearance & UI (screenshots JPG, dark mode, scroll bars)" ;;
    dock) echo "Dock & Dashboard (clear dock, autohide, hot corners)" ;;
    battery) echo "Battery (show percentage in menu bar)" ;;
    siri) echo "Siri & notifications (disable Siri, Preview persistence, notification gesture)" ;;
    trackpad) echo "Trackpad & mouse (tap to click, speed, scroll)" ;;
    keyboard) echo "Keyboard (smart punctuation off, disable Cmd+Space Spotlight for Raycast)" ;;
    finder) echo "Finder (downloads default, hidden files, trash, desktop icons)" ;;
    sharing) echo "Sharing (computer name)" ;;
    remove_media) echo "Remove iMovie, GarageBand, and Apple sound library paths (destructive)" ;;
    *) echo "Unknown" ;;
  esac
}

VALID_SECTIONS=(appearance dock battery siri trackpad keyboard finder sharing remove_media)
# Applied by --all and non-interactive runs: everything except the destructive remove_media.
DEFAULT_SECTIONS=(appearance dock battery siri trackpad keyboard finder sharing)

is_valid_section() {
  local s
  for s in "${VALID_SECTIONS[@]}"; do
    [[ "$s" == "$1" ]] && return 0
  done
  return 1
}

parse_sections_csv() {
  local csv="$1" part
  local -a parts
  SELECTED_SECTIONS=()
  IFS=',' read -ra parts <<<"${csv}" || true
  for part in "${parts[@]}"; do
    part="${part//[[:space:]]/}"
    [[ -n "$part" ]] || continue
    if ! is_valid_section "$part"; then
      die "Unknown section: ${part}. Valid: $(IFS=','; echo "${VALID_SECTIONS[*]}")"
    fi
    SELECTED_SECTIONS+=("$part")
  done
  [[ ${#SELECTED_SECTIONS[@]} -gt 0 ]] || die "--sections is empty or invalid"
}

prompt_sections() {
  local s ans
  SELECTED_SECTIONS=()
  echo ""
  echo "Choose which macOS defaults to apply (y = yes, Enter/n = skip):"
  echo ""
  for s in "${VALID_SECTIONS[@]}"; do
    read -r -p "  [$(section_label "$s")] [y/N]: " ans
    if [[ "${ans}" =~ ^[Yy]$ ]]; then
      SELECTED_SECTIONS+=("$s")
    fi
  done
  echo ""
}

decide_sections() {
  if [[ -n "$SECTIONS_CLI" ]]; then
    parse_sections_csv "$SECTIONS_CLI"
    return
  fi
  if $ALL; then
    SELECTED_SECTIONS=("${DEFAULT_SECTIONS[@]}")
    return
  fi
  if [[ -t 0 ]]; then
    prompt_sections
    return
  fi
  # Non-interactive stdin: apply the default sections so automated runs do not hang on read
  echo "Non-interactive stdin: applying all sections except remove_media. Use --sections=... or run in a terminal for prompts." >&2
  SELECTED_SECTIONS=("${DEFAULT_SECTIONS[@]}")
}

should_run() {
  local want="$1"
  local s
  for s in "${SELECTED_SECTIONS[@]}"; do
    [[ "$s" == "$want" ]] && return 0
  done
  return 1
}

section_appearance() {
  defaults write com.apple.screencapture type jpg
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' ||
    echo "Note: could not switch to dark mode (allow your terminal to control System Events under Privacy & Security → Automation)."
  defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
}

section_dock() {
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock tilesize -int 36
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock show-process-indicators -bool true
  defaults write com.apple.dock wvous-tl-corner -int 0
  defaults write com.apple.dock wvous-tr-corner -int 0
  defaults write com.apple.dock wvous-bl-corner -int 0
  defaults write com.apple.dock wvous-br-corner -int 0
  killall Dock 2>/dev/null || true
}

section_battery() {
  defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
  defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
}

section_siri() {
  defaults write com.apple.Preview ApplePersistenceIgnoreState YES
  defaults write com.apple.assistant.support "Assistant Enabled" -bool false
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 0
}

section_trackpad() {
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0
  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
  defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 5
}

section_keyboard() {
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  if [[ -f ~/Library/Preferences/com.apple.symbolichotkeys.plist ]]; then
    /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null || true
  fi
}

section_finder() {
  defaults write com.apple.finder NewWindowTarget -string "PfDe"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder "FXRemoveOldTrashItems" -bool true
  defaults write com.apple.finder ShowPreviewPane -bool true
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  chflags nohidden ~/Library 2>/dev/null || true
  killall Finder 2>/dev/null || true
}

section_sharing() {
  sudo scutil --set ComputerName "${COMPUTER_NAME}"
  sudo scutil --set LocalHostName "${LOCAL_HOST_NAME}"
  sudo scutil --set HostName "${LOCAL_HOST_NAME}"
}

section_remove_media() {
  sudo rm -rf /Applications/iMovie.app
  sudo rm -rf /Applications/GarageBand.app
  sudo rm -rf /Library/Application\ Support/GarageBand
  sudo rm -rf /Library/Application\ Support/Logic
  sudo rm -rf /Library/Audio/Apple\ Loops
}

# --- main --------------------------------------------------------------------

[[ "$(id -u)" -ne 0 ]] || die "Run as your user, not with sudo (defaults would be written for root). The script asks for sudo where needed."

decide_sections

if [[ ${#SELECTED_SECTIONS[@]} -eq 0 ]]; then
  echo "No sections selected. Nothing to do."
  exit 0
fi

# Ask for sudo once, up front, only when a selected section needs it; keep it alive meanwhile.
if should_run sharing || should_run remove_media; then
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

echo "Applying sections: ${SELECTED_SECTIONS[*]}"
echo ""

should_run appearance && section_appearance
should_run dock && section_dock
should_run battery && section_battery
should_run siri && section_siri
should_run trackpad && section_trackpad
should_run keyboard && section_keyboard
should_run finder && section_finder
should_run sharing && section_sharing
should_run remove_media && section_remove_media

echo "Settings applied. Note: Some changes require a logout/restart to take effect."
