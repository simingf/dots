# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
shopt -s checkwinsize

# make less handle non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Editor
export EDITOR='nvim'

# Prompt with git branch
parse_git_branch() {
  git branch 2>/dev/null | grep '*' | sed 's/* //'
}
PS1='bash|\[\e[36m\]\w\[\e[0m\]\[\e[33m\]$(b=$(parse_git_branch); [ -n "$b" ] && echo "($b)")\[\e[0m\]> '

# GCC colored warnings/errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# cd override: always clear+ls on directory change
cd() { builtin cd "$1" && clear && ls; }

# General aliases
alias e='exit'
alias c='clear && ls'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -r'
alias mkdir='mkdir -p'
alias ..='cd ..'
alias ...='cd ../..'

# Alert: desktop notification for long-running commands (e.g. `sleep 10; alert`)
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Config aliases
alias rs='source ~/.bashrc'
alias brc='nvim ~/.bashrc'

# Editor aliases
alias vim='nvim'
alias v='nvim'

# Claude
alias claude='claude --dangerously-skip-permissions'
alias kk='claude'

# tmux
alias trc='nvim ~/.tmux.conf'
alias trs='tmux source ~/.tmux.conf'
alias tl='tmux list-sessions'
alias tka='tmux kill-server'
tn() {
  [[ -z "$1" ]] && { echo "usage: tn <name>" >&2; return 1; }
  tmux has-session -t="$1" 2>/dev/null && tmux attach -t "$1" || tmux new -s "$1"
}
ta() {
  local session
  session=$(tmux list-sessions -F '#{session_name}' | fzf -q "${1:-}" --select-1 --exit-0) || return
  tmux attach -t "$session"
}
tk() {
  local session
  session=$(tmux list-sessions -F '#{session_name}' | fzf -q "${1:-}" --exit-0) || return
  tmux kill-session -t "$session"
}

# Bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook bash)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# devspace
export AD_USERNAME=sfeng
export VAULT_ENTITY_ID=
export VAULT_ADDR=http://127.0.0.1:8100
