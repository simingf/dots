# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

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

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

DISABLE_AUTO_TITLE="true"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi
alias v='nvim'

# enter alias
accept-line() {
    if [[ -z $BUFFER ]]; then
        zle -I
        # command to run when enter pressed
        clear && ls && echo
    else
        zle ".$WIDGET"
    fi
}
zle -N accept-line

# general aliases
alias e='exit'
# open in finder
alias f='open .'
# rm folders
alias rm='rm -r'
# accepts path name
alias mkdir='mkdir -p'
# print out path and copy the path
alias pwd='pwd && pwd | pbcopy'
# clears screenshot folder
alias css='rm -f ~/Screenshots/* && echo "screenshots cleared"'
# lists global node modules
alias npmg='npm list -g --depth 0'

# git
alias g='git status'
alias lg='lazygit'

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

# competitive programming alias
alias rr='make && ./sol'

# directory aliases
alias ls='ls -AG'
alias ..='builtin cd .. && clear && ls'
alias app='builtin cd /Applications/ && clear && ls'
alias doc='builtin cd ~/Documents/ && clear && ls'
alias dow='builtin cd ~/Downloads/ && clear && ls'
alias des='builtin cd ~/Desktop/ && clear && ls'
alias ss='builtin cd ~/Screenshots/ && clear && ls'
alias hub='builtin cd ~/Github/ && clear && ls'
alias lab='builtin cd ~/Gitlab/ && clear && ls'
alias euler='builtin cd ~/euler/ && clear && ls'
alias dp='builtin cd ~/atcoder-dp/ && clear && ls'
alias dots='builtin cd ~/dots && ls'

# vectraflow alias
alias vssh='kitten ssh sfeng@10.116.60.21'
alias vscp='scp -r * sfeng@10.116.60.21:~/continuous-query'

# conda
. "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"

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

# image magick function
img() {
    magick "$1" "$2"
    rm "$1"
}

# config aliases
alias cf="builtin cd ~/.config && ls"
# homebrew
alias bup='brew update && brew upgrade && brew cleanup && brew autoremove'
# zsh
alias zrc="nvim ~/.zshrc"
alias zrs="clear && source ~/.zshrc"
alias ch="rm -f ~/.zsh_history && clear"
# zinit
alias zup="zinit self-update && zinit update --parallel"
# nvim
alias nrc="nvim ~/.config/nvim/init.lua"
# kitty
alias krc="nvim ~/.config/kitty/kitty.conf"
# yabai
alias yrc="nvim ~/.config/yabai/yabairc"
alias yrs="yabai --restart-service" # && urs
yup() {
    TEXT="$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa"
    echo $TEXT | sudo tee /private/etc/sudoers.d/yabai
}
# skhd
alias src="nvim ~/.config/skhd/skhdrc"
alias srs="skhd --restart-service"
# restarts zshrc, yabai, skhd
alias rs='zrs && yrs && srs'
# updates zinit, homebrew and yabai
alias up='sudo echo && zup && bup && yup && yrs'

# ubersicht
# alias ub='builtin cd ~/.config/ubersicht/simple-bar && ls'
# urs() {
#     osascript -e 'tell application id "tracesOf.Uebersicht" to refresh'
# }

# cd() {
#     # if no DIR given, go home
#     if [[ "$@" == "" ]]; then
#         builtin cd $HOME && clear && ls
#     # if the path only contains '.' and '/' (moving up dir tree)
#     elif [[ "$@" =~ ^[./-]+$ ]]; then
#         builtin cd "$@" && clear && ls
#     # if the path contains at least one '/' (i tabbed it)
#     elif [[ "$@" == *"/"* ]]; then
#         builtin cd "$@" && clear && ls
#     else
#         # try to find exact match for dirname first
#         EXACT=$(find . -maxdepth 1 -type d -iname "$@" -print -quit)
#         if [[ $EXACT != "" ]]; then
#             builtin cd "${EXACT}" && clear && ls
#         else
#             # find all dirnames that contain search string
#             DIRS=$(find . -maxdepth 1 -type d -iname "*$@*" -print -quit)
#             if [[ $DIRS == "" ]]; then
#                 echo "ERROR: no match found" 
#             else
#                 # cd into first match
#                 DIR=${DIRS%%*"\n"}
#                 builtin cd "${DIR}" && clear && ls
#             fi
#         fi
#     fi
# }

