# Safe Chain and app/editor theme copies (sourced by ../setup.sh).

print_step "Installing Safe Chain"
install_safe_chain  # pinned version + checksum, see scripts/setup-00-lib.sh

print_step "Copying Warp terminal theme"
mkdir -p ~/.warp/themes/
run_or_die "Warp theme copy" cp "${SETUP_ROOT}/configs/warp-terminal-theme.yaml" ~/.warp/themes/warp-terminal-theme.yaml

print_step "Powerlevel10k: prompt config and Homebrew → Oh My Zsh theme symlink"
ensure_brew_shellenv
if [ -f "${HOME}/.p10k.zsh" ] && ! cmp -s "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"; then
  P10K_BACKUP="${HOME}/.p10k.zsh.backup-$(date +%Y%m%d%H%M%S)"
  cp "${HOME}/.p10k.zsh" "${P10K_BACKUP}"
  echo "Backed up existing ~/.p10k.zsh to ${P10K_BACKUP}"
fi
run_or_die "p10k user config copy" cp "${SETUP_ROOT}/configs/.p10k.zsh" "${HOME}/.p10k.zsh"
run_or_die "Powerlevel10k (brew) → ~/.oh-my-zsh/custom/themes/powerlevel10k" link_powerlevel10k_homebrew_to_omz
