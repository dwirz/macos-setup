#!/usr/bin/env bash
# Register Chrome Web Store extensions by ID using Chromium's "External Extensions"
# mechanism on macOS (small JSON files that point at the Web Store update URL).
#
# Writes the same manifests for Google Chrome and Arc (both are Chromium-based).
#
# GitLab MR Page Shortcuts (chrome extension id bdpocpafhnadlkdnmhlcpjhcedclolfn) is
# an unpacked extension in this repo and is not installed from the Web Store.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# Unpacked extension: GitLab MR Page Shortcuts (see chrome://extensions id bdpocpafhnadlkdnmhlcpjhcedclolfn)
GITLAB_UNPACKED_EXT="${REPO_ROOT}/configs/chrome-extensions/gitlab-merge-request"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
# Chrome: sibling to Default profile under the Chrome user-data root.
EXTERNAL_EXTENSIONS_DIR="${EXTERNAL_EXTENSIONS_DIR:-${HOME}/Library/Application Support/Google/Chrome/External Extensions}"
# Arc: user-data root is Arc/User Data (see Chromium layout); External Extensions sits next to Default/Profile *.
ARC_EXTERNAL_EXTENSIONS_DIR="${ARC_EXTERNAL_EXTENSIONS_DIR:-${HOME}/Library/Application Support/Arc/User Data/External Extensions}"
CHROME_UPDATE_URL="${CHROME_UPDATE_URL:-https://clients2.google.com/service/update2/crx}"

# Set SKIP_ARC=1 to only register extensions for Chrome.
# Set SKIP_CHROME=1 to only register for Arc.

# Chrome Web Store extension IDs from chrome://extensions (<extensions-item id="...">).
# Unpacked / local extensions are not listed here.
# Trailing # comments on each line are ignored by bash; edit the list as needed.
CHROME_EXTENSION_IDS=(
  aeblfdkhhhdcdjpifhhbdiojplfjncoa    # 1Password – Password Manager
  ndlbedplllcgconngcnfmkadhokfaaln    # GraphQL Network Inspector
  bcjindcccaagfpapjjmafapmmgkkhgoa    # JSON Formatter
  aicmkgpgakddgnaphhhpliifpcfhicfo    # Postman Interceptor
  chlffgpmiacpedhhbkiomidkjlcfhogd    # Pushbullet
  ldgfbffkinooeloadekpmfoklnobpien    # Raindrop.io
  fmkadmapgofadopljbjfkapdkoienihi    # React Developer Tools
  jjhefcfhmnkfeepcpnilbbkaadhngkbi    # Readwise Highlighter
  lmhkpmbekcpmknklioeibfkpmmfibljd    # Redux DevTools
  jcejahepddjnppkhomnidalpnnnemomn    # RSC Devtools
  cjpalhdlnbpafiamejdnhcphjbkeiagm    # uBlock Origin
)

die() {
  echo "Error: $*" >&2
  exit 1
}

write_external_manifest() {
  local id="$1"
  local ext_dir="$2"
  local manifest_path="${ext_dir}/${id}.json"
  cat >"${manifest_path}" <<EOF
{
  "external_update_url": "${CHROME_UPDATE_URL}"
}
EOF
}

TARGET_DIRS=()
if [[ "${SKIP_CHROME:-0}" != "1" ]]; then
  TARGET_DIRS+=("${EXTERNAL_EXTENSIONS_DIR}")
fi
if [[ "${SKIP_ARC:-0}" != "1" ]]; then
  TARGET_DIRS+=("${ARC_EXTERNAL_EXTENSIONS_DIR}")
fi

if [[ "${#TARGET_DIRS[@]}" -eq 0 ]]; then
  die "Nothing to do: both SKIP_CHROME and SKIP_ARC are set."
fi

for ext_dir in "${TARGET_DIRS[@]}"; do
  mkdir -p "${ext_dir}"
  echo "Writing external extension manifests to:"
  echo "  ${ext_dir}"
  for id in "${CHROME_EXTENSION_IDS[@]}"; do
    [[ -z "${id// }" ]] && continue
    echo "→ ${id}: writing manifest..."
    write_external_manifest "$id" "${ext_dir}"
  done
  echo ""
done

if [[ -f "${GITLAB_UNPACKED_EXT}/manifest.json" ]]; then
  echo "Local extension:"
  echo "  GitLab MR Page Shortcuts is unpacked at ${GITLAB_UNPACKED_EXT}"
  echo "  In each browser: open the extensions page → Developer mode → Load unpacked."
else
  echo "Note: Local GitLab MR extension not found at ${GITLAB_UNPACKED_EXT} (skipped)."
fi

if [[ -x "$CHROME" ]]; then
  :
else
  echo "Note: Google Chrome not found at ${CHROME} (external manifests were still written)."
fi

ARC_APP="${ARC:-/Applications/Arc.app}"
if [[ "${SKIP_ARC:-0}" != "1" ]] && [[ ! -d "$ARC_APP" ]]; then
  echo "Note: Arc not found at ${ARC_APP} — manifests are in place for when Arc is installed."
fi

echo "Done. Restart Google Chrome and/or Arc so they pick up Web Store extensions from the manifests."
