# ssh-dots — Claude Instructions

Shell rc files (`.bashrc`, `.zshrc`) for remote SSH dev boxes. Pushed to remotes via `scripts/push-ssh-dots.sh` (rsync to `~/`).

The push script also rsyncs pure-zsh plugins from the local zinit cache to `~/.local/share/<name>/` on the remote (arch-independent, no internet needed on the remote). Currently pushed: `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `omz-sudo`. The remote `.zshrc` sources each conditionally — missing plugin = silent fallback. fzf binary itself is assumed pre-installed on the remote (debian package) and its keybindings are sourced from `/usr/share/doc/fzf/examples/`.

Nvim setup is also pushed: `~/dots/.config/nvim/` → `~/.config/nvim/` (init.lua + lazy-lock.json) and `~/.local/share/nvim/lazy/` → same path on remote (Lua plugin tree). Mason and `~/.local/share/nvim/site/` (compiled treesitter parsers) are deliberately **not** pushed — they're arch-specific (arm64 macOS vs x86_64 Linux). Consequence on remote: LSPs are off, treesitter falls back to vim regex highlighting. Editor + plugin keymaps still work.

Loading order matters: `zsh-completions` before `compinit`, `fzf-tab` after `compinit`, `zsh-syntax-highlighting` last (it wraps ZLE).

## Keep bash and zsh symmetric

`.bashrc` and `.zshrc` should be identical aside from plugins and shell-syntax differences. Same alias names, same behavior, same section ordering. When the user adds something to one rc, mirror it to the other in the same edit.

Currently aligned:
- Prompt format: `<shell>|<cwd>(<git-branch>)>`
- History size, dedup, ignore-leading-space
- Aliases: `e`, `c`, `ll`, `la`, `l`, `rm`, `mkdir`, `npmg`, `..`, `...`, `cf`, `nrc`, `vim`, `v`, `lg`, `trc`, `trs`, `tl`, `tka`, `claude`, `kk`, `kkr`
- Functions: `tn`, `ta`, `tk`, `sup`, `pbcopy` stub
- `c`: clear+ls; `cd` (or `chpwd`): clear+ls on every dir change
- `rs`: `clear && source <rc>`
- `ch`: wipe history + clear
- Shell-specific edit alias: `brc` (bash) / `zrc` (zsh)
- tmux precmd updates window title to basename of `$PWD`
- Exports: `EDITOR`, `GCC_COLORS`, `GH_HOST`, `PATH` additions, `NVM_DIR`, devspace vars
- direnv + nvm hooks

Intentional asymmetries:
- **bash auto-execs zsh** at startup if zsh is on PATH (`SHLVL <= 1` guard so `bash` from inside zsh stays bash). The login shell on the remote is bash; this is the workaround. The rest of `.bashrc` only runs as a fallback when zsh is missing.
- **zsh has plugins, bash doesn't.** zsh sources `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `OMZP::sudo` from `~/.local/share/`. Bash has no equivalent for autosuggestions / syntax-highlighting / fzf-tab without `ble.sh` (heavy, intrusive). Cheap parities (fzf keybindings, Esc-Esc sudo) aren't worth adding because bash should never actually be the interactive shell.
- zsh has `_tmux_preexec` (sets title to running command); bash doesn't — DEBUG-trap implementation isn't worth the complexity given bash exec's into zsh.
- Color setup: bash uses `dircolors`, zsh uses direct aliases — both produce colored `ls`.
- Completion: bash sources `bash-completion`, zsh uses `compinit` + zstyles — shell-idiomatic.
