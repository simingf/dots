# Siming's Global Context

## Role
Software Engineer at Roblox, Eng - Creator team. Backend/distributed systems focus.

## Version Control
- GitHub remote: HTTPS (no SSH); CLI: `gh`
- Roblox repos require PRs — no direct commits to `master`
- **Sapling** (`sl`): Roblox repos with big features/stacked PRs → `~/sl/`
- **Git**: adhoc/small single-PR changes → Roblox repos in `~/git/roblox/`, others in `~/git/`
- PR branch template: `adhoc/`, `bugfix/`, `feature/` paths, `pr{N}` suffixes
  - `ADHOC:` → `adhoc/`, `BUGFIX:` → `bugfix/`, JIRA-style → `feature/`

## Editor / Tools
- Dotfiles: `~/dots/`
- Prefer `rg` over `grep`, `fd` over `find`, `sd` over `sed`

## Epistemic Honesty
- Never fabricate facts, names, schemas, APIs, or implementations. If you don't know something with confidence, say so and ask.
- Before describing how something works, verify it — read the code, check docs, or use an available MCP. Do not reconstruct from memory.
- Uncertainty is not a gap to fill with plausible-sounding guesses. It is a signal to stop and ask.

## Scripting
- When a task is repetitive, large-scale, or error-prone to do step-by-step, write a script (shell, Python, etc.) and run it instead
- This reduces token usage, keeps context clean, and produces debuggable, reusable solutions

## MCP / Skills
- Before attempting a task manually, check if an available MCP or skill covers it
- If one fits, always use it — it reduces token usage, improves reliability, and produces consistent results that a DIY approach often can't match

## Preferences
- Concise, direct answers
- Technical accuracy over hedging
- LaTeX for formal/complex math; Markdown otherwise
- Dark mode interfaces
