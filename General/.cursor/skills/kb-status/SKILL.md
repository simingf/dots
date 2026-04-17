---
description: One-shot vault health dashboard for the Roblox knowledge-bank at /Users/sfeng/roblox-obsidian. Shows note counts by type, freshness buckets, open proposals awaiting review, the last run of every maintenance skill, and recent git activity. Read-only — never mutates the vault. Use when the user asks "status of the vault", "vault dashboard", "what's pending review", "how healthy is the knowledge base", "when was the vault last maintained", or similar.
globs:
alwaysApply: false
---

# kb-status

Single-command answer to "what's the state of the vault right now?"

No edits, no commits. Not part of `kb-weekly` (because it produces no artifacts to aggregate). Runs in under a second.

## Preflight

1. `test -d /Users/sfeng/roblox-obsidian/00-Meta || { echo "not a vault root"; exit 1; }`
2. `python3 --version` (stdlib only; no pip installs).
3. No lock, no dirty-tree requirement — this skill reads.

## Work

### 1. Run the aggregator

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/status.py --json > /tmp/kb-status.json
```

### 2. Present the dashboard

Read `/tmp/kb-status.json` and render exactly the sections below. Keep the output compact — the user is scanning, not reading.

```
Vault: /Users/sfeng/roblox-obsidian   (today: <YYYY-MM-DD>)
Notes: <note_count>

Notes by type
  <type>  <count>    (one per line, sorted alphabetically)

Freshness
  <=30d    <count>
  31-90d   <count>
  91-365d  <count>
  >365d    <count>
  missing  <count>

Open proposals (<count>)
  <filename>   <bytes>B   mtime <mtime>   (one per line, empty if none)

Maintenance last-run
  <skill>   last_run_at=<ts>   <counters>
  (from last-run.yaml; one line per skill under schema_version)

Git activity (last 7 days, <N> commits)
  <date> <subject>
  (up to 10; truncate with "… and <N-10> more" if longer)
```

If any of the five sections is empty, still print the heading and `(none)` beneath it so the shape of the dashboard stays constant.

### 3. Offer follow-ups

End with a short "common follow-ups" block tailored to what the dashboard shows:

- `missing > 0` → "Run `kb-freshness` to see which notes need `last_verified:` bumps."
- open proposals present → "Review `00-Meta/Maintenance/proposals/<filename>` and act on it."
- `last_run_at` empty or > 7d old for any maintenance skill → "Run `kb-weekly` to refresh all sub-skills in one sweep."
- Git activity quiet (0 commits in 7d) → no follow-up; this is normal.

Only surface follow-ups that are actually triggered by the data — never fabricate.

## Finalize

No finalize steps. No lock, no manifest regen, no commit. If invoked with `KB_DRIVEN_BY=kb-weekly`, refuse: this skill is on-demand only and is not wired into the weekly sweep.

## Non-goals

- Does not edit any note.
- Does not touch `last-run.yaml`, logs, or proposals.
- Does not fetch from Sourcegraph, Confluence, or any other external source — the dashboard is vault-local.
- Does not profile the vault for integrity, freshness, dedupe, or linkrot. Those belong to their dedicated skills; `kb-status` is just a summary view.
