#!/usr/bin/env bash
set -euo pipefail

# Install "U.S. with German Umlauts" keyboard layout (Option+a => ä, etc.).
# Upstream: https://github.com/patrick-zippenfenig/us-with-german-umlauts
#
# After install: System Settings → Keyboard → Input Sources → add "U.S. with German Umlauts".
# When updating the pin, bump COMMIT_SHA and recompute EXPECTED_SHA256 from the tarball:
#   curl -sL "https://api.github.com/repos/patrick-zippenfenig/us-with-german-umlauts/tarball/<SHA>" | shasum -a 256

REPO="patrick-zippenfenig/us-with-german-umlauts"
COMMIT_SHA="ad3886c0e8091853136594ede685792a471ccd31"
EXPECTED_SHA256="223f2aa36f5ab319c78cc952afd3820f03a83a48dbd49c23afc2ccec154649e2"
TARBALL_URL="https://api.github.com/repos/${REPO}/tarball/${COMMIT_SHA}"
TARGET_DIR="/Library/Keyboard Layouts"

TMP="$(mktemp -t us-umlauts.XXXXXX)"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

curl -fsSL "$TARBALL_URL" -o "$TMP"

if ! echo "${EXPECTED_SHA256}  ${TMP}" | shasum -a 256 -c - >/dev/null 2>&1; then
  echo "SHA-256 mismatch for ${TARBALL_URL}" >&2
  echo "Expected: ${EXPECTED_SHA256}" >&2
  echo "Got:      $(shasum -a 256 "$TMP" | awk '{print $1}')" >&2
  exit 1
fi

echo "SHA-256 OK (${COMMIT_SHA:0:7}…); installing to ${TARGET_DIR} (requires sudo)…"
sudo tar xzf "$TMP" --exclude=README.md --strip=1 -C "${TARGET_DIR}"

echo "Installed. Add the layout in Keyboard → Input Sources if needed."
