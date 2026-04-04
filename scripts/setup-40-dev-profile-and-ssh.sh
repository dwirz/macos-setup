# Dev profile (Node/npm/Git) and SSH setup (sourced by ../setup.sh).

print_step "Applying Node, npm, and Git profile setup"
DEV_PROFILE_SETUP_SCRIPT="./scripts/setup-dev-profile.sh"
if [ -f "$DEV_PROFILE_SETUP_SCRIPT" ]; then
  chmod +x "$DEV_PROFILE_SETUP_SCRIPT"
  run_or_die "dev profile setup" "$DEV_PROFILE_SETUP_SCRIPT" "$NAME" "$EMAIL" "$DOMAIN"
else
  echo "Skipping dev profile setup: $DEV_PROFILE_SETUP_SCRIPT not found."
fi

print_step "Running interactive SSH key setup"
SSH_SETUP_SCRIPT="./scripts/setup-ssh.sh"
if [ -f "$SSH_SETUP_SCRIPT" ]; then
  chmod +x "$SSH_SETUP_SCRIPT"
  run_or_die "SSH setup" "$SSH_SETUP_SCRIPT" "$EMAIL"
else
  echo "Skipping SSH setup: $SSH_SETUP_SCRIPT not found."
fi
