---
description: Flag stale notes in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Compares each note's last_verified against per-type thresholds in 00-Meta/Maintenance/freshness-config.yaml. Propose-only — never edits notes. Use when the user asks "what's stale?", "freshness check", "what needs re-verifying", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-freshness

Flag notes whose `last_verified:` age exceeds the type's configured threshold. This skill is strictly propose-only — it never touches note bodies or frontmatter. The user re-verifies a note against the live system, bumps its `last_verified:` to today, and commits. **kb-freshness will not do that for you.**

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` — the umbrella has already done them.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-freshness $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Maintenance/README.md` (auto-apply vs. propose-for-review policy) and `00-Meta/Maintenance/freshness-config.yaml` (thresholds in effect).

## Work

### 1. Run the freshness scanner + emit sidecar

```bash
cd /Users/sfeng/roblox-obsidian
TODAY=$(date -u +%F)
python3 00-Meta/Scripts/freshness.py --json \
  --emit-sidecar "00-Meta/Maintenance/proposals/staleness-${TODAY}.apply.yaml" \
  > /tmp/kb-freshness.json
```

The scanner is read-only. It reports `stale_count`, `stale[]` with per-note age and threshold, `missing_last_verified[]`, and the resolved `thresholds` dict. Each stale note also becomes a `set_frontmatter last_verified=<today>` action in the sidecar — **default-unchecked**, because a freshness bump requires the human to actually re-verify before flipping the box. `kb-verify` is the interactive companion that flips boxes one-at-a-time.

### 2. Write the proposal (only if anything stale OR missing)

If `stale_count == 0` AND `missing_last_verified` is empty, skip this step. Otherwise write:

```
00-Meta/Maintenance/proposals/staleness-$(date -u +%F).md
```

Body:

```markdown
---
type: index
schema_version: 1
proposal_kind: staleness
generated_at: <ISO-8601-UTC>
today: <YYYY-MM-DD>
---

## Summary

- stale notes: <stale_count>
- notes missing `last_verified:` <n>

## Action

For each note below, re-verify its contents against the live system (Sourcegraph, Confluence, Mosaic, the actual service, etc.), THEN tick the matching checkbox and run `kb-apply` to bump `last_verified:`. Do NOT blind-tick without verifying — that defeats the point. Use `kb-verify` for a guided one-at-a-time prompt.

## Proposed actions

- [ ] `freshness-bump-<slug>` — <type>: <name>  (age=<age>d)

<one bullet per stale entry; all default-unchecked>

## Stale by Type

### <type-A>

| name   | path   | age (d) | threshold (d) |
| ------ | ------ | ------- | ------------- |
| <name> | <path> | <age>   | <threshold>   |

<one subsection per type present in the stale list, sorted alphabetically by type; within each, sorted by -age>

## Missing `last_verified:`

| path   | type   |
| ------ | ------ |
| <path> | <type> |

<only if any>
```

### 3. Emit counters

Print one JSON line to stdout so the umbrella can aggregate:

```json
{"skill":"kb-freshness","stale":<n>,"missing_date":<n>,"proposals":<0-or-1>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append the JSON counters line to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-freshness.md`.
2. **Update `last-run.yaml`** — set `kb-freshness.last_run_at` to `$(date -u +%FT%TZ)`, `kb-freshness.outcome` to `clean` if `stale == 0 && missing_date == 0` else `proposals_created`, and `kb-freshness.stale_flagged` to the JSON `stale` count.
3. **Commit (only if the proposal file was written).** kb-freshness never mutates notes, so a no-proposal run has nothing to commit except `last-run.yaml` — that's fine, commit it.
   ```bash
   git add -A
   git commit -m "kb-freshness: <stale> stale, <missing> missing-date"
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- Config parse errors: surface them; do not silently fall back to `default: inf` for a typo'd key. Abort, leave tree clean, release lock.
- The scanner should never crash on a well-formed vault. If it does, capture the stack trace and abort — treat as a bug in `freshness.py`, not in the vault.

## Non-goals

- kb-freshness never edits notes. It never bumps `last_verified:`. It never moves files. Its single job is to tell the user what deserves attention.
- kb-freshness never deletes old proposal files. `kb-weekly`'s aggregator does that.
