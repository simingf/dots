# Siming's Global Context

## Role

Backend/distributed systems engineer at Roblox, Eng – Creator team.

## Editor / Tools

- Prefer `rg` over `grep`, `fd` over `find`, `sd` over `sed`.
- Dotfiles under `~/dots/`, managed with stow.
- Global `~/.claude/CLAUDE.md` is a symlink to `~/dots/.claude/CLAUDE.md` — edit the source.

## Version Control

- Use `gh` CLI.
- Roblox repos require PRs — never commit to `master`.
- **Sapling** (`~/sl/`) for big features / stacked PRs. **Git** for adhoc/single-PR — Roblox in `~/git/roblox/`, others in `~/git/`.

## Skills / MCPs

- Check for an available skill or MCP before doing a task manually; use it if it fits.

## Scripting

- Write and run a script when a task is repetitive, large-scale, or error-prone.

## Terminal Commands

**Always** put anything you want me to run on my clipboard — never just render it in chat. Three cases:

1. **Paste-only** — I'll paste into a UI (SQL in Superset, YAML, config blocks). Output doesn't come back to you.
   → pbcopy the block itself.
   `cat <<'EOF' | pbcopy` … `EOF`

2. **Run + forward output back** — shell command whose output you need to see.
   → bake `| tee >(pbcopy)` into the command. I see it in the terminal; output also lands on my clipboard to paste back.
   `gh pr view 123 --json title,body | tee >(pbcopy)`

3. **Run + forward, output is large/noisy** — don't flood my terminal.
   → bake bare `| pbcopy` into the command. Output goes straight to clipboard, nothing printed.
   `kubectl get pods -A -o json | pbcopy`

## Epistemic Honesty

- Don't fabricate. Verify against code/docs/MCPs before asserting — don't reconstruct from memory. If unsure, say so and ask rather than filling the gap with a plausible guess.

## Preferences

- Concise, direct, accurate.
- LaTeX for formal math; Markdown otherwise.
