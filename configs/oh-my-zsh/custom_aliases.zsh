# ZSH Aliases
alias profile="cursor ~/.zshrc" # Opens the bash profile file
alias aliases="cursor ~/.oh-my-zsh/custom/custom_aliases.zsh" # Open this file
alias functions="cursor ~/.oh-my-zsh/custom/custom_functions.zsh" # Open functions file
alias envvars="cursor ~/.oh-my-zsh/custom/custom_env_variables.zsh" # Open env variables file
alias startup="cursor ~/.oh-my-zsh/custom/custom_startup.zsh" # Open startup file

# Directory Aliases
alias ..="cd .." # Change directories
alias cdd="cd ~/Desktop" # Go to desktop
alias ll="eza -alh" # Long list files and directories
alias ls="eza -a" # Short list files and directories

# System Aliases
alias df='df -h' # Human readable free disk space
alias du='ncdu' # Human readable disk space stats
alias cpu="top -o cpu" # Display cpu usage
alias btop="btop -lc" # Better version of top

# Console Aliases
alias cls="clear"
alias h=history # Display command history
alias nccat="grep -v \"^\s*#\"" # Show file contents without comments

# File Aliases
alias f="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'" # Fuzzy search files
alias fcat='bat $(f)' # Fuzzy search a file and open it in bat
alias fcode='cursor $(f)' # Fuzzy search a file and open it in cursor
alias hosts="cursor /private/etc/hosts" # Open hosts file
alias cat="bat" # Use bat as cat

# Node Aliases
alias nr="npm run"
alias nrd="nr dev"
alias nci="npm ci"

# Docker Aliases
alias docker-stop-all="docker stop $(docker ps -q)"
alias docker-rm-all="docker rm $(docker ps -a -q)"
alias docker-rm-all-imgs="docker rmi $(docker images -q)"

# Git Aliases
alias setup-main='
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  read "NEW_BRANCH?Enter the branch to set as origin'\''s default [${CURRENT_BRANCH}]: "
  NEW_BRANCH=${NEW_BRANCH:-$CURRENT_BRANCH}
  git remote set-head origin $NEW_BRANCH && \
  echo "origin/HEAD is now: $(git symbolic-ref refs/remotes/origin/HEAD | sed \"s@^refs/remotes/origin/@@\")"
'
alias main='((git add -A && git stash) || true) && git checkout $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@") && git pull'
alias rebase='BRANCH=$(git symbolic-ref --short HEAD) && main && git checkout $BRANCH && git rebase $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@") && git stash pop'

# Netbird aliases
alias bird-link-pin='netbird expose 3000 --with-pin 608005'
alias bird-link-team='netbird expose 3000 --with-user-groups smartive'

# Headroom — safe local proxy for Cursor BYOK (localhost, no persistence, no telemetry)
headroom:cursor() {
  export HEADROOM_TELEMETRY=off
  export HEADROOM_UPDATE_CHECK=off
  export HEADROOM_HOST=127.0.0.1
  export HEADROOM_PORT=8787
  export HEADROOM_CCR_BACKEND=memory
  export HEADROOM_STATELESS=true
  unset HEADROOM_LOG_MESSAGES HEADROOM_LOG_FILE

  if ! command -v headroom >/dev/null 2>&1; then
    local install_script="${MACOS_SETUP_ROOT:-${HOME}/projects/private/macos-setup}/scripts/install-headroom.sh"
    if [ -x "${install_script}" ]; then
      "${install_script}" || return 127
    else
      echo "headroom not found and install script missing: ${install_script}"
      return 127
    fi
    command -v headroom >/dev/null 2>&1 || {
      echo "headroom still not on PATH after install; open a new shell or ensure ~/.local/bin is on PATH"
      return 127
    }
  fi

  echo "Starting Headroom (safe local). First load may take 30–90s."
  echo "Paste printed OpenAI/Anthropic base URLs into Cursor → Settings → Models (BYOK + overrides)."
  headroom wrap cursor --port "${HEADROOM_PORT}"
}

# Other Aliases
alias tf="terraform"
alias tmbliss-dev="tmbliss run --path ~/projects"
alias scheduled-jobs="grep -l -E 'StartCalendarInterval|StartInterval' ~/Library/LaunchAgents/*.plist 2>/dev/null"
alias custom-aliases="grep -E '^[[:space:]]*alias[[:space:]]' ~/.oh-my-zsh/custom/custom_aliases.zsh"
