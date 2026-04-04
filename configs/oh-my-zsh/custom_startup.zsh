# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Add SSH keys to the agent
ssh-add -K ~/.ssh/id_rsa &> /dev/null
ssh-add -A &> /dev/null

# Update PATHs
export DOCKER_BIN=$HOME/.docker/bin
export PATH="$DOCKER_BIN:$PATH"

# NVM setup
export NVM_DIR="/Users/dwirz/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Homebrew setup
eval "$(/opt/homebrew/bin/brew shellenv)"

# Oh My Zsh setup
export ZSH="/Users/dwirz/.oh-my-zsh"
plugins=(git autojump docker docker-compose docker_commands)
fpath+=("$(brew --prefix)/share/zsh/site-functions")
source "$ZSH/oh-my-zsh.sh"
ZSH_THEME=""

# Powerlevel10k setup
# https://github.com/romkatv/powerlevel10k
source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aikido setup
source ~/.safe-chain/scripts/init-posix.sh

# Run nvm use when entering a directory with a .nvmrc file
autoload -Uz add-zsh-hook
add-zsh-hook chpwd nvm_auto_use
function nvm_auto_use() {
  if [[ -f .nvmrc ]]; then
    nvm use
  fi
}

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# Welcome the user
echo "Welcome back" $(id -F | awk '{print $1;}')"! 🚀 (Tip: Use 'custom-aliases' to see all aliases)"
