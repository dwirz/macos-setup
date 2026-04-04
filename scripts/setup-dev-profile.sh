#!/usr/bin/env bash

set -euo pipefail

NAME="${1:-Your Name}"
EMAIL="${2:-you@your-domain.com}"
DOMAIN="${3:-your-domain.com}"

# Load nvm (Homebrew installs to $(brew --prefix nvm); manual install uses ~/.nvm)
if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  export NVM_DIR="${HOME}/.nvm"
  # shellcheck source=/dev/null
  . "${NVM_DIR}/nvm.sh"
elif command -v brew >/dev/null 2>&1; then
  _NVM_PREFIX="$(brew --prefix nvm 2>/dev/null || true)"
  if [ -n "${_NVM_PREFIX}" ] && [ -s "${_NVM_PREFIX}/nvm.sh" ]; then
    export NVM_DIR="${_NVM_PREFIX}"
    # shellcheck source=/dev/null
    . "${_NVM_PREFIX}/nvm.sh"
  fi
fi

if ! declare -F nvm >/dev/null 2>&1; then
  echo "Error: nvm not loaded. Install nvm (e.g. brew install nvm) and ensure nvm.sh can be sourced." >&2
  exit 1
fi

# Setup Node
# Install latest node version (LTS)
nvm install --lts
# Use the latest node version
nvm use --lts
# Set current node version as default
nvm alias default node
# Install latest npm
npm i -g npm@latest
# Set npm init author name, email and url
npm set init-author-name="$NAME"
npm set init-author-email="$EMAIL"
npm set init-author-url="$DOMAIN"

# Optional: authenticate npm account now
read -r -p "Run 'npm adduser' now? [y/N]: " RUN_NPM_ADDUSER
if [[ "$RUN_NPM_ADDUSER" =~ ^[Yy]$ ]]; then
  npm adduser
else
  echo "Skipping npm login. Run 'npm adduser' later."
fi

# Setup Git
# Set git user name and email
git config --global user.name "$NAME"
git config --global user.email "$EMAIL"
# Improve git log
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
