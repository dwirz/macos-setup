#!/usr/bin/env bash
# shellcheck disable=SC2088 # "~/..." in messages is display text, not a path
# doctor.sh — check this Mac against the repo, repair what is missing or broken, and
# clean up leftovers of tools this repo no longer manages.
#
#   ./doctor.sh                    check only (changes nothing)
#   ./doctor.sh --fix              also repair what can be repaired safely
#   ./doctor.sh --cleanup          also remove leftovers (asks per item)
#   ./doctor.sh --fix --cleanup --yes   do both without asking
#
# Safe to re-run any time. Runs with macOS's /bin/bash 3.2 (no bash 4 features).
# Exit code: 0 when nothing is left to do, 1 when problems remain.

set -uo pipefail

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/setup-00-lib.sh
source "${SETUP_ROOT}/scripts/setup-00-lib.sh"

BREWFILE="${SETUP_ROOT}/Brewfile"
FIX=0
CLEANUP=0
YES=0

usage() {
  # Print the header comment (after the shellcheck line) up to the first non-comment line.
  awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fix) FIX=1 ;;
    --cleanup) CLEANUP=1 ;;
    --yes | -y) YES=1 ;;
    --help | -h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# --- reporting ---------------------------------------------------------------

PROBLEMS=0   # problems found (fail + leftovers)
FIXED=0      # problems repaired or removed in this run
NOTES=0      # warnings that need a look but no automatic fix

section() { printf '\n== %s\n' "$1"; }
ok() { printf '  ✓ %s\n' "$*"; }
note() { printf '  ! %s\n' "$*"; NOTES=$((NOTES + 1)); }
fail() { printf '  ✗ %s\n' "$*"; PROBLEMS=$((PROBLEMS + 1)); }
hint() { printf '      → %s\n' "$*"; }
detail() { sed 's/^/      /'; }

# fix "what it does" command...  — runs with --fix, otherwise prints how to repair.
fix() {
  local desc="$1"
  shift
  if [ "${FIX}" = 1 ]; then
    printf '      fixing: %s\n' "${desc}"
    if "$@"; then
      FIXED=$((FIXED + 1))
      printf '      ✓ fixed\n'
    else
      printf '      ✗ fix failed (see output above)\n'
    fi
  else
    hint "${desc}  (./doctor.sh --fix)"
  fi
}

confirm() {
  [ "${YES}" = 1 ] && return 0
  [ -t 0 ] || return 1
  local answer
  read -r -p "      $1 [y/N]: " answer
  case "${answer}" in [yY] | [yY][eE][sS]) return 0 ;; esac
  return 1
}

# leftover "what is left" "how to remove it" command...  — removes with --cleanup.
leftover() {
  local what="$1" desc="$2"
  shift 2
  printf '  ✗ %s\n' "${what}"
  PROBLEMS=$((PROBLEMS + 1))
  if [ "${CLEANUP}" = 1 ]; then
    if confirm "${desc}?"; then
      if "$@"; then
        FIXED=$((FIXED + 1))
        printf '      ✓ removed\n'
      else
        printf '      ✗ removal failed (see output above)\n'
      fi
    else
      printf '      skipped\n'
    fi
  else
    hint "${desc}  (./doctor.sh --cleanup)"
  fi
}

# Move an app bundle to the Trash instead of deleting it.
move_to_trash() {
  local target
  target="${HOME}/.Trash/$(basename "$1")"
  [ -e "${target}" ] && target="${target%.app}-$(date +%Y%m%d%H%M%S).app"
  mv "$1" "${target}"
}

# Delete lines equal to $2 from file $1 (portable; no sed -i).
remove_line() {
  local file="$1" line="$2" tmp
  [ -f "${file}" ] || return 0
  tmp="$(mktemp)" || return 1
  grep -vxF -- "${line}" "${file}" >"${tmp}"
  cat "${tmp}" >"${file}" && rm -f "${tmp}"
}

ensure_brew_shellenv
HAVE_BREW=0
command -v brew >/dev/null 2>&1 && brew --prefix >/dev/null 2>&1 && HAVE_BREW=1

brew_has_formula() { [ "${HAVE_BREW}" = 1 ] && brew list --formula "$1" >/dev/null 2>&1; }
brew_has_cask() { [ "${HAVE_BREW}" = 1 ] && brew list --cask "$1" >/dev/null 2>&1; }
brew_unused() { [ -z "$(brew uses --installed "$1" 2>/dev/null)" ]; }

NVM_SH=""
if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  NVM_SH="${HOME}/.nvm/nvm.sh"
elif [ "${HAVE_BREW}" = 1 ] && [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
  NVM_SH="$(brew --prefix)/opt/nvm/nvm.sh"
fi
# Run nvm in a subshell (nvm.sh is not `set -u` safe), always with NVM_DIR=~/.nvm.
nvm_run() {
  (
    set +u
    export NVM_DIR="${HOME}/.nvm"
    mkdir -p "${NVM_DIR}"
    # shellcheck source=/dev/null
    . "${NVM_SH}" >/dev/null 2>&1
    nvm "$@"
  )
}
fix_node_lts() { nvm_run install --lts && nvm_run alias default 'lts/*'; }

install_oh_my_zsh() {
  local installer
  installer="$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || return 1
  sh -c "${installer}" "" --unattended
}

# Subshell: install_safe_chain exits on failure, which must not end the doctor.
install_safe_chain_isolated() { (install_safe_chain); }

# Chrome Web Store IDs wanted by scripts/install-chrome-extensions.sh (single source of truth).
wanted_extension_ids() {
  sed -n '/^CHROME_EXTENSION_IDS=(/,/^)/p' "${SETUP_ROOT}/scripts/install-chrome-extensions.sh" |
    awk '{print $1}' | grep -E '^[a-p]{32}$'
}

echo "macos-setup doctor — repo: ${SETUP_ROOT}"
[ "${FIX}" = 1 ] && echo "Mode: repair (--fix)"
[ "${CLEANUP}" = 1 ] && echo "Mode: cleanup (--cleanup)"

# --- leftovers (first, so they cannot block installs below) -------------------

section "Leftovers from tools this repo no longer manages"
LEFTOVERS_BEFORE=${PROBLEMS}

if command -v pipx >/dev/null 2>&1 && pipx list --short 2>/dev/null | grep -q '^headroom-ai '; then
  leftover "Headroom (pipx package headroom-ai)" "pipx uninstall headroom-ai" pipx uninstall headroom-ai
fi

OPENSCREEN_VENV="${HOME}/.local/share/macos-setup/venv-install-release"
if [ -d "${OPENSCREEN_VENV}" ]; then
  leftover "install-release venv used by the old OpenScreen script (${OPENSCREEN_VENV})" \
    "delete ${OPENSCREEN_VENV}" rm -rf "${OPENSCREEN_VENV}"
fi

if [ -d "/Applications/Openscreen.app" ] && ! brew_has_cask openscreen; then
  leftover "/Applications/Openscreen.app is not from Homebrew (old archived version?); it blocks the openscreen cask" \
    "move /Applications/Openscreen.app to the Trash" move_to_trash "/Applications/Openscreen.app"
fi

if brew_has_cask cursor; then
  leftover "Cursor (Homebrew cask)" "brew uninstall --cask cursor" brew uninstall --cask cursor
elif [ -d "/Applications/Cursor.app" ]; then
  leftover "/Applications/Cursor.app" "move /Applications/Cursor.app to the Trash" move_to_trash "/Applications/Cursor.app"
fi

if brew_has_cask loom; then
  leftover "Loom (Homebrew cask, removed from the Brewfile)" "brew uninstall --cask loom" brew uninstall --cask loom
fi

# Formulae the Brewfile dropped. Only offered when nothing installed depends on them.
for formula in pure zsh-async libmagic; do
  if brew_has_formula "${formula}" && brew_unused "${formula}"; then
    leftover "${formula} (removed from the Brewfile, nothing depends on it)" \
      "brew uninstall ${formula}" brew uninstall "${formula}"
  fi
done
# pipx and python@3.13 were only added for Headroom; keep them while any pipx app is installed.
hash -r
if brew_has_formula pipx && [ -z "$(pipx list --short 2>/dev/null)" ] && brew_unused pipx; then
  leftover "pipx (only used for Headroom; no other pipx apps installed)" "brew uninstall pipx" brew uninstall pipx
fi
hash -r
if brew_has_formula python@3.13 && brew_unused python@3.13 && ! command -v pipx >/dev/null 2>&1; then
  leftover "python@3.13 (only used for Headroom; nothing depends on it)" "brew uninstall python@3.13" brew uninstall python@3.13
fi

if [ "${HAVE_BREW}" = 1 ] && [ -d "$(brew --prefix)/opt/nvm/versions" ]; then
  leftover "Node versions inside Homebrew's nvm folder ($(brew --prefix)/opt/nvm/versions); the shell uses ~/.nvm" \
    "delete $(brew --prefix)/opt/nvm/versions" rm -rf "$(brew --prefix)/opt/nvm/versions"
fi

for legacy in "${HOME}/.fzf.zsh" "${HOME}/.fzf.bash"; do
  if [ -f "${legacy}" ]; then
    leftover "${legacy} from fzf's old install script (fzf now loads via \`fzf --zsh\`)" "delete ${legacy}" rm -f "${legacy}"
  fi
done
if [ -f "${HOME}/.bashrc" ] && grep -qxF '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' "${HOME}/.bashrc"; then
  leftover "fzf line in ~/.bashrc" "remove the fzf line from ~/.bashrc" \
    remove_line "${HOME}/.bashrc" '[ -f ~/.fzf.bash ] && source ~/.fzf.bash'
fi

WANTED_IDS="$(wanted_extension_ids)"
for ext_dir in "${HOME}/Library/Application Support/Google/Chrome/External Extensions" \
  "${HOME}/Library/Application Support/Arc/User Data/External Extensions"; do
  [ -d "${ext_dir}" ] || continue
  for manifest in "${ext_dir}"/*.json; do
    [ -f "${manifest}" ] || continue
    id="$(basename "${manifest}" .json)"
    grep -q 'clients2.google.com/service/update2/crx' "${manifest}" || continue
    if ! printf '%s\n' "${WANTED_IDS}" | grep -qx "${id}"; then
      leftover "Extension manifest for ${id} (no longer in the list) in ${ext_dir}" \
        "delete ${manifest}" rm -f "${manifest}"
    fi
  done
done

[ "${PROBLEMS}" = "${LEFTOVERS_BEFORE}" ] && ok "No leftovers found"

# --- system ------------------------------------------------------------------

section "Command Line Tools and Homebrew"
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode Command Line Tools: $(xcode-select -p)"
else
  fail "Xcode Command Line Tools are missing"
  fix "open Apple's installer (finish it, then re-run the doctor)" xcode-select --install
fi

if [ "${HAVE_BREW}" = 1 ]; then
  ok "Homebrew $(brew --version 2>/dev/null | head -1 | awk '{print $2}') at $(brew --prefix)"
else
  fail "Homebrew is not installed or not working"
  hint "run ./setup.sh (installs Homebrew); the checks that need Homebrew are skipped"
fi

if [ "${HAVE_BREW}" = 1 ]; then
  section "Brewfile"
  if brew bundle check --no-upgrade --file="${BREWFILE}" >/dev/null 2>&1; then
    ok "Every Brewfile entry is installed"
  else
    fail "Brewfile entries are missing:"
    brew bundle check --no-upgrade --verbose --file="${BREWFILE}" 2>&1 | grep '^→' | detail
    fix "brew bundle install --no-upgrade --file=${BREWFILE}" \
      brew bundle install --no-upgrade --file="${BREWFILE}"
  fi

  # Deprecated or disabled formulae/casks: they will stop installing at some point.
  if command -v jq >/dev/null 2>&1; then
    BUNDLE_CASKS="$(brew bundle list --cask --file="${BREWFILE}" 2>/dev/null)"
    BUNDLE_FORMULAE="$(brew bundle list --formula --file="${BREWFILE}" 2>/dev/null)"
    # shellcheck disable=SC2086 # word splitting of the name lists is intended
    DEPRECATED="$({
      [ -n "${BUNDLE_FORMULAE}" ] && brew info --json=v2 --formula ${BUNDLE_FORMULAE} 2>/dev/null
      [ -n "${BUNDLE_CASKS}" ] && brew info --json=v2 --cask ${BUNDLE_CASKS} 2>/dev/null
    } | jq -r '(.formulae[]?, .casks[]?)
        | select(.deprecated or .disabled)
        | "\(.full_token // .full_name): \(if .disabled then "disabled" else "deprecated" end) (\(.disable_reason // .deprecation_reason // "no reason given"))"' | sort -u)"
    if [ -n "${DEPRECATED}" ]; then
      note "Deprecated or disabled in Homebrew (replace or remove from the Brewfile):"
      printf '%s\n' "${DEPRECATED}" | detail
    else
      ok "No deprecated or disabled Brewfile entries"
    fi
  fi

  # Dry run; keep only the "Would uninstall …"/"Would untap" lists (not brew cleanup's cache preview).
  UNTRACKED="$(brew bundle cleanup --file="${BREWFILE}" </dev/null 2>/dev/null |
    awk '/^Would (uninstall|untap)/ { p = 1; print; next } /^(Would|Run |==>)/ { p = 0 } p && NF')"
  if [ -n "${UNTRACKED}" ]; then
    note "Installed but not in the Brewfile (add what you want to keep to the Brewfile):"
    printf '%s\n' "${UNTRACKED}" | detail
    hint "to uninstall all of them: brew bundle cleanup --force --file=${BREWFILE}  (check the list first)"
  else
    ok "Nothing installed outside the Brewfile"
  fi
fi

# --- shell -------------------------------------------------------------------

section "Shell (zsh, Oh My Zsh, Powerlevel10k, fzf)"
if [ -d "${HOME}/.oh-my-zsh" ]; then
  ok "Oh My Zsh is installed"
else
  fail "Oh My Zsh is missing"
  fix "install Oh My Zsh (unattended)" install_oh_my_zsh
fi

LINKS_OK=1
[ "$(readlink "${HOME}/.zshrc" 2>/dev/null)" = "${SETUP_ROOT}/configs/.zshrc-custom" ] || LINKS_OK=0
for f in ${OMZ_CUSTOM_FILES}; do
  [ "$(readlink "${HOME}/.oh-my-zsh/custom/${f}" 2>/dev/null)" = "${SETUP_ROOT}/configs/oh-my-zsh/${f}" ] || LINKS_OK=0
done
if [ "${LINKS_OK}" = 1 ]; then
  ok "~/.zshrc and Oh My Zsh custom files link to this repo"
else
  fail "~/.zshrc or Oh My Zsh custom files do not link to this repo"
  fix "re-link them (a regular ~/.zshrc is backed up first)" link_shell_configs
fi

if [ -f "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  ok "Powerlevel10k theme is linked into Oh My Zsh"
else
  fail "Powerlevel10k theme is not linked into ~/.oh-my-zsh/custom/themes"
  fix "link Homebrew's powerlevel10k into Oh My Zsh" link_powerlevel10k_homebrew_to_omz
fi

if [ ! -f "${HOME}/.p10k.zsh" ]; then
  fail "~/.p10k.zsh is missing"
  fix "copy configs/.p10k.zsh to ~/.p10k.zsh" cp "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"
elif cmp -s "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"; then
  ok "~/.p10k.zsh matches the repo"
else
  note "~/.p10k.zsh differs from configs/.p10k.zsh (not overwritten; it may hold your customizations)"
  hint "compare: diff ${SETUP_ROOT}/configs/.p10k.zsh ~/.p10k.zsh — copy the one you want over the other"
fi

if git -C "${SETUP_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
  [ -n "$(git -C "${SETUP_ROOT}" status --porcelain -- configs/.zshrc-custom configs/oh-my-zsh 2>/dev/null)" ]; then
  note "Shell configs in the repo have uncommitted changes (installers that append to ~/.zshrc write into the repo)"
  hint "review: git -C ${SETUP_ROOT} diff -- configs/.zshrc-custom configs/oh-my-zsh"
fi

if command -v zsh >/dev/null 2>&1 && [ -f "${HOME}/.zshrc" ]; then
  ZSH_ERRORS="$(zsh -c 'source ~/.zshrc' 2>&1 >/dev/null)"
  if [ -z "${ZSH_ERRORS}" ]; then
    ok "~/.zshrc loads without errors"
  else
    note "~/.zshrc prints errors when loaded:"
    printf '%s\n' "${ZSH_ERRORS}" | head -8 | detail
  fi
fi

if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    ok "fzf $(fzf --version | awk '{print $1}') supports \`fzf --zsh\`"
  else
    fail "fzf is too old for \`fzf --zsh\` (needs 0.48+)"
    fix "brew upgrade fzf" brew upgrade fzf
  fi
fi

# --- node --------------------------------------------------------------------

section "Node (nvm)"
if [ -z "${NVM_SH}" ]; then
  fail "nvm is not installed (expected Homebrew's nvm or ~/.nvm/nvm.sh)"
  hint "the Brewfile installs it: ./doctor.sh --fix"
else
  LTS_VERSION="$(nvm_run version 'lts/*' 2>/dev/null)"
  if [ -n "${LTS_VERSION}" ] && [ "${LTS_VERSION}" != "N/A" ]; then
    ok "Node LTS ${LTS_VERSION} is installed in ~/.nvm"
    if nvm_run alias default 2>/dev/null | grep -q 'default -> lts/\*'; then
      ok "nvm default is lts/*"
    else
      fail "nvm default is not lts/* ($(nvm_run alias default 2>/dev/null | head -1))"
      fix "nvm alias default 'lts/*'" nvm_run alias default 'lts/*'
    fi
  else
    fail "No Node LTS installed in ~/.nvm"
    fix "nvm install --lts and make it the default" fix_node_lts
  fi
fi

# --- security & network --------------------------------------------------------

section "SSH, Safe Chain, NetBird"
SSH_CONFIG="${HOME}/.ssh/config"
SSH_BLOCK_START="# >>> macos-setup ssh defaults >>>"
add_ssh_ignore_unknown() {
  local tmp
  tmp="$(mktemp)" || return 1
  awk -v start="${SSH_BLOCK_START}" '
    { print }
    $0 == start { in_block = 1; next }
    in_block && $0 == "Host *" { print "  IgnoreUnknown UseKeychain"; in_block = 0 }
  ' "${SSH_CONFIG}" >"${tmp}" && cat "${tmp}" >"${SSH_CONFIG}" && rm -f "${tmp}"
}
if [ -f "${SSH_CONFIG}" ] && grep -qxF "${SSH_BLOCK_START}" "${SSH_CONFIG}"; then
  if grep -q 'IgnoreUnknown UseKeychain' "${SSH_CONFIG}"; then
    ok "~/.ssh/config has the macos-setup block with IgnoreUnknown UseKeychain"
  else
    fail "~/.ssh/config: UseKeychain without IgnoreUnknown (breaks if a non-Apple ssh is used)"
    fix "add 'IgnoreUnknown UseKeychain' to the macos-setup block" add_ssh_ignore_unknown
  fi
else
  note "~/.ssh/config has no macos-setup block"
  hint "run ${SETUP_ROOT}/scripts/setup-ssh.sh (interactive)"
fi

if [ -f "${HOME}/.safe-chain/scripts/init-posix.sh" ]; then
  ok "Safe Chain is installed"
else
  fail "Safe Chain is not installed (~/.safe-chain/scripts/init-posix.sh missing)"
  fix "install the pinned Safe Chain release" install_safe_chain_isolated
fi

if command -v netbird >/dev/null 2>&1; then
  if netbird status >/dev/null 2>&1; then
    ok "NetBird daemon is running"
  else
    note "NetBird daemon is not running"
    hint "sudo netbird service install --management-url https://netbird.smarties.app && sudo netbird service start"
  fi
fi
if [ -f "${HOME}/.env" ] && grep -qE '^(export )?NETBIRD_EXPOSE_PIN=' "${HOME}/.env"; then
  ok "NETBIRD_EXPOSE_PIN is set in ~/.env"
else
  note "NETBIRD_EXPOSE_PIN is not set in ~/.env (needed by the bird-link-pin alias)"
fi

# --- apps & extras -----------------------------------------------------------------

section "Browser extensions, keyboard layout, tmbliss, Git"
MISSING_MANIFESTS=0
for ext_dir in "${HOME}/Library/Application Support/Google/Chrome/External Extensions" \
  "${HOME}/Library/Application Support/Arc/User Data/External Extensions"; do
  for id in ${WANTED_IDS}; do
    [ -f "${ext_dir}/${id}.json" ] || MISSING_MANIFESTS=$((MISSING_MANIFESTS + 1))
  done
done
if [ "${MISSING_MANIFESTS}" = 0 ]; then
  ok "Web Store extension manifests are in place for Chrome and Arc"
else
  fail "${MISSING_MANIFESTS} Web Store extension manifest(s) missing for Chrome/Arc"
  fix "write the manifests (restart the browsers afterwards)" bash "${SETUP_ROOT}/scripts/install-chrome-extensions.sh"
fi

if [ -d "/Library/Keyboard Layouts/US-with-German-Umlauts.bundle" ]; then
  ok "U.S. with German Umlauts keyboard layout is installed"
else
  fail "U.S. with German Umlauts keyboard layout is missing"
  fix "install it (asks for sudo)" "${SETUP_ROOT}/scripts/install-us-with-german-umlauts.sh"
fi

TMBLISS_PLIST="${HOME}/Library/LaunchAgents/com.tmbliss.daily.plist"
if [ -f "${TMBLISS_PLIST}" ]; then
  TMBLISS_BIN_IN_PLIST="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "${TMBLISS_PLIST}" 2>/dev/null)"
  if [ -n "${TMBLISS_BIN_IN_PLIST}" ] && [ ! -x "${TMBLISS_BIN_IN_PLIST}" ]; then
    fail "tmbliss LaunchAgent points to a missing binary: ${TMBLISS_BIN_IN_PLIST}"
    hint "re-create it: ${SETUP_ROOT}/scripts/setup-tmbliss-launchagent.sh (interactive)"
  elif launchctl print "gui/$(id -u)/com.tmbliss.daily" >/dev/null 2>&1; then
    ok "tmbliss LaunchAgent is loaded"
  else
    fail "tmbliss LaunchAgent exists but is not loaded"
    fix "launchctl bootstrap it" launchctl bootstrap "gui/$(id -u)" "${TMBLISS_PLIST}"
  fi
else
  note "No tmbliss LaunchAgent (optional)"
  hint "set it up: ${SETUP_ROOT}/scripts/setup-tmbliss-launchagent.sh (interactive)"
fi

if [ -n "$(git config --global user.email 2>/dev/null)" ] && [ -n "$(git config --global user.name 2>/dev/null)" ]; then
  ok "Git identity: $(git config --global user.name) <$(git config --global user.email)>"
else
  fail "Global Git user.name or user.email is not set"
  hint "git config --global user.name \"Your Name\" && git config --global user.email you@example.com"
fi

# --- summary -----------------------------------------------------------------

REMAINING=$((PROBLEMS - FIXED))
printf '\n== Summary\n'
printf '  %d problem(s) found, %d fixed or removed, %d remaining; %d note(s) to review.\n' \
  "${PROBLEMS}" "${FIXED}" "${REMAINING}" "${NOTES}"
if [ "${REMAINING}" -gt 0 ]; then
  [ "${FIX}" = 0 ] || [ "${CLEANUP}" = 0 ] && echo "  Re-run with --fix and/or --cleanup to repair, or follow the hints above."
  exit 1
fi
echo "  All good."
exit 0
