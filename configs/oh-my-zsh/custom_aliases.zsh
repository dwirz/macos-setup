# ZSH Aliases
alias profile="code ~/.zshrc" # Open the zsh profile file
alias aliases="code ~/.oh-my-zsh/custom/custom_aliases.zsh" # Open this file
alias functions="code ~/.oh-my-zsh/custom/custom_functions.zsh" # Open functions file
alias envvars="code ~/.oh-my-zsh/custom/custom_env_variables.zsh" # Open env variables file

# Directory Aliases
alias ..="cd .." # Change directories
alias cdd="cd ~/Desktop" # Go to desktop
alias ll="eza -alh" # Long list files and directories
alias ls="eza -a" # Short list files and directories

# System Aliases
alias df='df -h' # Human readable free disk space
alias cpu="top -o cpu" # Display cpu usage

# Console Aliases
alias cls="clear"
alias h=history # Display command history
alias nccat="grep -v \"^\s*#\"" # Show file contents without comments

# File Aliases
alias f="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'" # Fuzzy search files
alias fcat='bat $(f)' # Fuzzy search a file and open it in bat
alias fcode='code $(f)' # Fuzzy search a file and open it in VS Code
alias hosts="code /private/etc/hosts" # Open hosts file
alias cat="bat" # Use bat as cat

# Node Aliases
alias nr="npm run"
alias nrd="nr dev"
alias nci="npm ci"

# Docker Aliases
# Single quotes: the $(...) must run when the alias is used, not when the shell starts
alias docker-stop-all='docker stop $(docker ps -q)'
alias docker-rm-all='docker rm $(docker ps -a -q)'
alias docker-rm-all-imgs='docker rmi $(docker images -q)'

# Git Aliases
alias setup-main='
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  read "NEW_BRANCH?Enter the branch to set as origin'\''s default [${CURRENT_BRANCH}]: "
  NEW_BRANCH=${NEW_BRANCH:-$CURRENT_BRANCH}
  git remote set-head origin $NEW_BRANCH && \
  echo "origin/HEAD is now: $(git symbolic-ref refs/remotes/origin/HEAD | sed \"s@^refs/remotes/origin/@@\")"
'
alias main='((git add -A && git stash) || true) && git checkout $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@") && git pull'
# Pops the stash only if `main` actually created one (otherwise an older, unrelated stash would be applied)
alias rebase='BRANCH=$(git symbolic-ref --short HEAD) && STASH_BEFORE=$(git rev-parse -q --verify refs/stash || true) && main && git checkout $BRANCH && git rebase $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@") && if [ "$(git rev-parse -q --verify refs/stash || true)" != "$STASH_BEFORE" ]; then git stash pop; fi'

# Netbird aliases
# PIN comes from NETBIRD_EXPOSE_PIN (set it in ~/.env, which is not in this repo)
alias bird-link-pin='netbird expose 3000 --with-pin "${NETBIRD_EXPOSE_PIN:?set NETBIRD_EXPOSE_PIN in ~/.env}"'
alias bird-link-team='netbird expose 3000 --with-user-groups smartive'

# Other Aliases
alias tf="terraform"
alias tmbliss-dev="tmbliss run --path ~/projects"
alias scheduled-jobs="grep -l -E 'StartCalendarInterval|StartInterval' ~/Library/LaunchAgents/*.plist 2>/dev/null"
alias custom-aliases="grep -E '^[[:space:]]*alias[[:space:]]' ~/.oh-my-zsh/custom/custom_aliases.zsh"
