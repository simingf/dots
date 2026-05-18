#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-sfeng-dev.coder}"
SRC="$HOME/dots/ssh-dots"
ZINIT="$HOME/.local/share/zinit"

# Prefer Homebrew rsync (supports --info=progress2 for a clean single-line bar);
# fall back to system openrsync with per-file --progress.
if [[ -x /opt/homebrew/bin/rsync ]]; then
    RSYNC=/opt/homebrew/bin/rsync
    PROGRESS=(--info=progress2 --info=name0)
else
    RSYNC=rsync
    PROGRESS=(--progress)
fi

step() { printf '\n\033[1;36m→ %s\033[0m\n' "$*" >&2; }

step "ssh-dots → ~"
"$RSYNC" -az "${PROGRESS[@]}" "$SRC"/ "$HOST":~/

ssh "$HOST" 'mkdir -p ~/.local/share' >/dev/null

push_plugin() {
    local src="$1" dst="$2"
    if [[ -d "$src" ]]; then
        step "plugin: $dst"
        "$RSYNC" -az "${PROGRESS[@]}" "$src"/ "$HOST":"~/.local/share/$dst/"
    else
        echo "warn: missing $src — skipping" >&2
    fi
}

push_plugin "$ZINIT/plugins/Aloxaf---fzf-tab"                    fzf-tab
push_plugin "$ZINIT/plugins/zsh-users---zsh-autosuggestions"     zsh-autosuggestions
push_plugin "$ZINIT/plugins/zsh-users---zsh-syntax-highlighting" zsh-syntax-highlighting
push_plugin "$ZINIT/plugins/zsh-users---zsh-completions"         zsh-completions
push_plugin "$ZINIT/snippets/OMZP::sudo"                         omz-sudo

step "nvim config"
ssh "$HOST" 'mkdir -p ~/.config/nvim ~/.local/share/nvim/lazy' >/dev/null
"$RSYNC" -azL "${PROGRESS[@]}" "$HOME"/dots/.config/nvim/ "$HOST":~/.config/nvim/

if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
    step "nvim plugin tree (~112MB; slow on first push, incremental after)"
    "$RSYNC" -az "${PROGRESS[@]}" "$HOME"/.local/share/nvim/lazy/ "$HOST":~/.local/share/nvim/lazy/
fi
