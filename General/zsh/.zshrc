# Homebrew
if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

export GH_HOST=github.rbx.com

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# Oh My Posh prompt
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $HOME/dots/General/ohmyposh/zen.toml)"
fi

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# disable automatic window title
DISABLE_AUTO_TITLE="true"

# Execute on Enter
accept-line() {
    if [[ -z $BUFFER ]]; then
        zle -I
        # command to run when enter pressed
        clear && ls -G
    else
        zle ".$WIDGET"
    fi
}
zle -N accept-line

# Shell integrations
source <(fzf --zsh)
eval "$(zoxide init --cmd cd zsh)"

# general aliases
alias e='exit'
alias ll='ls -la'
alias f='open .'
alias rm='rm -r'
alias mkdir='mkdir -p'
alias pwd='pwd && pwd | pbcopy'
alias npmg='npm list -g --depth 0'
alias icat="kitten icat"
alias top="btop"

# directory aliases
alias ls='ls -G'
alias ..='builtin cd .. && clear && ls'
alias ...='builtin cd ../.. && clear && ls'
alias app='builtin cd /Applications/ && clear && ls'
alias doc='builtin cd ~/Documents/ && clear && ls'
alias dow='builtin cd ~/Downloads/ && clear && ls'
alias des='builtin cd ~/Desktop/ && clear && ls'
alias dots='builtin cd ~/dots && ls'

# config aliases
alias cf="builtin cd ~/.config && ls"
# homebrew
alias bup='brew update && brew upgrade && brew cleanup && brew autoremove'
# zsh
alias zrc="nvim ~/.zshrc"
alias rs="clear && source ~/.zshrc"
alias ch="rm -f ~/.zsh_history && clear"
# zinit
alias zup="zinit self-update && zinit update --all && zinit cclear"
# nvim
alias nrc="nvim ~/.config/nvim/init.lua"
# kitty
alias krc="nvim ~/.config/kitty/kitty.conf"
# aerospace
alias arc="nvim ~/.config/aerospace/aerospace.toml"
# updates zinit, homebrew
alias up='zup && bup'

# nvim
alias vim='nvim'
alias v='nvim'

# ripgrep
export RIPGREP_CONFIG_PATH=~/.config/ripgrep/rg.conf
alias rg="rg --hyperlink-format=kitty"

# lazygit
alias lg='echo -ne "\033]0;$(basename $(git rev-parse --show-toplevel 2>/dev/null) || echo "Lazygit")\007" && lazygit'

# sl update
alias sup='echo "➡️ pulling..." && sl pull && echo "➡️ rebasing on newest master..." && sl rebase -d master && echo "➡️ restacking..." && sl restack && echo "➡️ submitting prs..." && sl pr submit --stack'

# work aliases
alias swarplogin='swarp login sitetest3 && swarp secrets refresh sitetest3'
alias swarprun='swarp run --watch'
alias pps='portpal serve'
alias kk='declawd'

# competitive programming
alias cpr='make && ./sol'

# goto PR (https://github.rbx.com/Roblox/creator-cu/pull/267/files)
gotopr() {
  local url="$1"
  local repo=$(echo "$url" | sed 's|.*/\([^/]*\)/pull/.*|\1|')
  local pr=$(echo "$url" | sed 's|.*/pull/\([0-9]*\).*|\1|')
  local org=$(echo "$url" | sed 's|.*/\([^/]*\)/[^/]*/pull/.*|\1|')
  local host=$(echo "$url" | sed 's|https://\([^/]*\)/.*|\1|')

  echo "➡️ PR #$pr in $host/$org/$repo"

  echo "➡️ cd ~/git..."
  cd ~/git

  if [ -d "$repo" ]; then
    echo "➡️ Repo found, fetching latest..."
    cd "$repo" && git fetch --prune
  else
    echo "➡️ Repo not found, cloning $repo..."
    git clone "https://${host}/${org}/${repo}.git"
    cd "$repo"
  fi

  echo "➡️ Checking out PR #$pr..."
  gh pr checkout "$pr"

  echo "➡️ Opening in Cursor..."
  cursor .
}

# vscode
k() {
    if [[ "$@" == "" ]]; then
        code .
    else
        code "$@"
    fi
}

# python
p() {
    if [[ "$@" == "" ]]; then
        echo "python: no file given"
    else
        python3 "$@"
    fi
}

# conda
c() {
    if [[ "$@" == "" ]]; then
        clear
    elif [[ "$1" == "a" ]]; then
        shift
        conda activate "$@"
    elif [[ "$@" == "d" ]]; then
        conda deactivate
    else
        conda "$@"
    fi
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/git/skills-cli/bin:$PATH"

# Reminders MacTeX
path+=/Library/TeX/texbin