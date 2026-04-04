#!/usr/bin/env bash
set -euo pipefail

# Apply repo wallpaper (desktop), lock screen image, and Photos screensaver folder.
# Usage: ./scripts/apply-wallpaper-lockscreen-screensaver.sh [SETUP_ROOT]
# Default SETUP_ROOT is the parent of this script's directory.

SETUP_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WALLPAPER_IMG="${SETUP_ROOT}/etc/love-sign.png"
LOCKSCREEN_IMG="${SETUP_ROOT}/etc/lieblings-agentur.png"

if [ ! -f "$WALLPAPER_IMG" ] || [ ! -f "$LOCKSCREEN_IMG" ]; then
  echo "Skipping wallpaper/lock screen/screensaver: images not found under ${SETUP_ROOT}/etc/" >&2
  exit 0
fi

# Desktop (all displays)
if ! osascript <<APPLESCRIPT
tell application "System Events"
  tell every desktop
    set picture to POSIX file "${WALLPAPER_IMG//\"/\\\"}"
  end tell
end tell
APPLESCRIPT
then
  echo "Note: Setting desktop picture failed; grant Terminal/Cursor Automation for System Events if prompted." >&2
fi

sleep 2

# Lock screen (Ventura+): replace lockscreen.png in Desktop Pictures cache
LOCK_PNG=""
while IFS= read -r f; do
  if [ -w "$f" ]; then
    LOCK_PNG="$f"
    break
  fi
done < <(find "/Library/Caches/Desktop Pictures" -name lockscreen.png -type f 2>/dev/null)

if [ -n "$LOCK_PNG" ]; then
  cp -f "$LOCKSCREEN_IMG" "$LOCK_PNG" || echo "Warning: could not copy lock screen image to ${LOCK_PNG}" >&2
else
  echo "Lock screen cache not found (no lockscreen.png under /Library/Caches/Desktop Pictures)." >&2
  echo "  Open System Settings > Wallpaper or Lock Screen once, then run this script again." >&2
fi

# Screensaver: Photos (iLifeSlideshows) + folder
SCREENSAVER_FOLDER="${HOME}/Pictures/Screensaver/macos-setup"
mkdir -p "$SCREENSAVER_FOLDER"
cp -f "$LOCKSCREEN_IMG" "${SCREENSAVER_FOLDER}/lieblings-agentur.png" || {
  echo "Warning: could not copy image to ${SCREENSAVER_FOLDER}" >&2
}

ILIFE_PATH="/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex"
if [ ! -d "$ILIFE_PATH" ]; then
  echo "Screensaver not configured: iLifeSlideshows missing at ${ILIFE_PATH}" >&2
  exit 0
fi

defaults -currentHost write com.apple.screensaver moduleDict -dict \
  moduleName "iLifeSlideshows" \
  path "$ILIFE_PATH" \
  type 0

defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedFolderPath "$SCREENSAVER_FOLDER"
defaults -currentHost write com.apple.ScreenSaverPhotoChooser CustomFolderDict -dict \
  identifier "$SCREENSAVER_FOLDER" \
  name "macos-setup"

killall cfprefsd 2>/dev/null || true
killall WallpaperAgent 2>/dev/null || true

echo "Wallpaper, lock screen (if cache existed), and screensaver folder updated."
