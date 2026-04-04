#!/usr/bin/env bash

set -euo pipefail

EMAIL_HINT="${1:-}"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
MANAGED_BLOCK_START="# >>> macos-setup ssh defaults >>>"
MANAGED_BLOCK_END="# <<< macos-setup ssh defaults <<<"
DEFAULT_KEY_NAME="github"
KEY_PATH=""

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

echo ""
echo "Running interactive SSH key setup"

read -r -p "Use an existing SSH private key file? [y/N]: " USE_EXISTING_KEY
if [[ "$USE_EXISTING_KEY" =~ ^[Yy]$ ]]; then
  read -r -p "Enter full path to private key file: " SOURCE_KEY_PATH
  if [ -f "$SOURCE_KEY_PATH" ]; then
    KEY_BASENAME="$(basename "$SOURCE_KEY_PATH")"
    KEY_PATH="$SSH_DIR/$KEY_BASENAME"

    if [ "$SOURCE_KEY_PATH" != "$KEY_PATH" ]; then
      cp "$SOURCE_KEY_PATH" "$KEY_PATH"
    fi
    chmod 600 "$KEY_PATH"

    if [ -f "${SOURCE_KEY_PATH}.pub" ]; then
      cp "${SOURCE_KEY_PATH}.pub" "${KEY_PATH}.pub"
      chmod 644 "${KEY_PATH}.pub"
    else
      echo "Public key not found at ${SOURCE_KEY_PATH}.pub (you can create one later)."
    fi
  else
    echo "Provided key path does not exist. Continuing to key generation prompt."
  fi
fi

if [ -z "$KEY_PATH" ]; then
  read -r -p "Generate a new SSH key now? [Y/n]: " GENERATE_NEW_KEY
  if [[ ! "$GENERATE_NEW_KEY" =~ ^[Nn]$ ]]; then
    read -r -p "Key file name in ~/.ssh (default: $DEFAULT_KEY_NAME): " KEY_NAME_INPUT
    KEY_NAME="${KEY_NAME_INPUT:-$DEFAULT_KEY_NAME}"
    KEY_PATH="$SSH_DIR/$KEY_NAME"

    if [ -f "$KEY_PATH" ]; then
      read -r -p "Key '$KEY_PATH' already exists. Overwrite? [y/N]: " OVERWRITE_KEY
      if [[ "$OVERWRITE_KEY" =~ ^[Yy]$ ]]; then
        rm -f "$KEY_PATH" "${KEY_PATH}.pub"
      else
        echo "Keeping existing key file."
      fi
    fi

    if [ ! -f "$KEY_PATH" ]; then
      if [ -n "$EMAIL_HINT" ]; then
        ssh-keygen -t ed25519 -C "$EMAIL_HINT" -f "$KEY_PATH"
      else
        ssh-keygen -t ed25519 -f "$KEY_PATH"
      fi
    fi
  fi
fi

if [ -z "$KEY_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  read -r -p "Enter existing key filename in ~/.ssh to configure (e.g. github): " EXISTING_KEY_NAME
  KEY_PATH="$SSH_DIR/$EXISTING_KEY_NAME"
fi

if [ ! -f "$KEY_PATH" ]; then
  echo "No usable key found at '$KEY_PATH'. Skipping SSH config changes."
  exit 0
fi

if /usr/bin/grep -Fq "$MANAGED_BLOCK_START" "$SSH_CONFIG"; then
  TMP_CONFIG="$(mktemp)"
  awk -v start="$MANAGED_BLOCK_START" -v end="$MANAGED_BLOCK_END" '
    $0 == start { skipping = 1; next }
    $0 == end { skipping = 0; next }
    !skipping { print }
  ' "$SSH_CONFIG" > "$TMP_CONFIG"
  mv "$TMP_CONFIG" "$SSH_CONFIG"
fi

{
  echo ""
  echo "$MANAGED_BLOCK_START"
  echo "Host *"
  echo "  AddKeysToAgent yes"
  echo "  UseKeychain yes"
  echo "  IdentityFile $KEY_PATH"
  echo "$MANAGED_BLOCK_END"
} >> "$SSH_CONFIG"

chmod 600 "$SSH_CONFIG"

if ssh-add --apple-use-keychain "$KEY_PATH" >/dev/null 2>&1; then
  echo "SSH key added to macOS keychain: $KEY_PATH"
elif ssh-add -K "$KEY_PATH" >/dev/null 2>&1; then
  echo "SSH key added using legacy keychain flag: $KEY_PATH"
elif ssh-add "$KEY_PATH" >/dev/null 2>&1; then
  echo "SSH key added to ssh-agent: $KEY_PATH"
else
  echo "Could not add key to agent automatically. Run: ssh-add --apple-use-keychain $KEY_PATH"
fi

if [ -f "${KEY_PATH}.pub" ]; then
  echo "Public key ready: ${KEY_PATH}.pub"
  echo "Use this to copy it: pbcopy < ${KEY_PATH}.pub"
fi
