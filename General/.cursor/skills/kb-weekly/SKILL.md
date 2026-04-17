---
description: Weekly Roblox knowledge-bank vault upkeep at /Users/sfeng/roblox-obsidian. Runs every maintenance check in one sweep — integrity, freshness, dedupe, reorganize, linkrot, archive, reindex. Produces one aggregated proposals/weekly-YYYY-MM-DD.md and one commit. Use when the user asks for weekly upkeep, vault maintenance, "run the whole thing", or has no specific sub-task in mind.
globs:
alwaysApply: false
---

# kb-weekly (umbrella)

One weekly sweep that composes every maintenance sub-skill's `## Work` section under a single lock, a single manifest regen, and a single commit.

Phase status of the step list:

- Phase 1: `kb-integrity`.
- Phase 2: adds `kb-freshness`, `kb-dedupe`.
- Phase 3 (now): adds `kb-reorganize`, `kb-linkrot`, `kb-archive`, `kb-reindex`.

Follow the exact workflow below — no free-form prose, no improvisation, no skipping steps.

## Workflow

Print `Task Progress:` with the checklist below when starting. Update it as each step completes.

```
Task Progress:
- [ ] Step 0: Preflight  (git clean; no lock held; vault root confirmed)
- [ ] Step 1: Acquire 00-Meta/.lock
- [ ] Step 2: Export KB_DRIVEN_BY=kb-weekly
- [ ] Step 3:  kb-integrity   (read ~/.cursor/skills/kb-integrity/SKILL.md,   follow its Work section only — Preflight and Finalize are skipped because KB_DRIVEN_BY is set)
- [ ] Step 3b: kb-freshness   (read ~/.cursor/skills/kb-freshness/SKILL.md,   follow its Work section only)
- [ ] Step 3c: kb-dedupe      (read ~/.cursor/skills/kb-dedupe/SKILL.md,      follow its Work section only)
- [ ] Step 3d: kb-reorganize  (read ~/.cursor/skills/kb-reorganize/SKILL.md,  follow its Work section only)
- [ ] Step 3e: kb-linkrot     (read ~/.cursor/skills/kb-linkrot/SKILL.md,     follow its Work section only)
- [ ] Step 3f: kb-archive     (read ~/.cursor/skills/kb-archive/SKILL.md,     follow its Work section only)
- [ ] Step 3g: kb-reindex     (read ~/.cursor/skills/kb-reindex/SKILL.md,     follow its Work section only — this is the one auto-apply sub-skill)
- [ ] Step 4: Regenerate manifest  (python3 00-Meta/Scripts/manifest.py)
- [ ] Step 5: Aggregate proposals  (merge any new proposals/integrity-*.md, staleness-*.md, dedupe-*.md, reorganize-*.md, linkrot-*.md, archive-*.md, and queued ingest-spec-stubs-*.md / ingest-pr-stubs-*.md into proposals/weekly-YYYY-MM-DD.md)
- [ ] Step 6: Write logs/YYYY-MM-DD-kb-weekly.md with per-step counters
- [ ] Step 7: Update last-run.yaml  (kb-weekly + 7 sub-skills)
- [ ] Step 8: git commit -m "kb-weekly: <summary>"
- [ ] Step 9: Release lock
```

---

### Step 0 — Preflight

```bash
cd /Users/sfeng/roblox-obsidian
test -d 00-Meta || { echo "not a vault root"; exit 1; }
git status --porcelain | grep -q . && { echo "dirty tree; aborting"; exit 1; }
test -f 00-Meta/.lock && { echo "lock held; aborting"; exit 1; }
```

### Step 1 — Acquire lock

```bash
echo "kb-weekly $(date -u +%FT%TZ)" > 00-Meta/.lock
```

### Step 2 — Set driver flag

Export `KB_DRIVEN_BY=kb-weekly` for the remainder of the sweep. Sub-skills branch around their Preflight/Finalize when this is set.

```bash
export KB_DRIVEN_BY=kb-weekly
```

### Step 3 — Run kb-integrity (Work section only)

1. Read `~/.cursor/skills/kb-integrity/SKILL.md`.
2. Execute ONLY its `## Work` section — every step in `## Preflight` and `## Finalize` is gated on `KB_DRIVEN_BY` and becomes a no-op.
3. Capture the JSON counters line it prints.

On error: jump to Step 9a (abort path).

### Step 3b — Run kb-freshness (Work section only)

1. Read `~/.cursor/skills/kb-freshness/SKILL.md`.
2. Execute ONLY its `## Work` section (runs `freshness.py --json`, writes `proposals/staleness-*.md` only if `stale_count > 0` or any `missing_last_verified`).
3. Capture the JSON counters line it prints.

On error: jump to Step 9a. kb-freshness is propose-only and cannot corrupt the vault, so partial failure here is recoverable; still, abort the sweep for cleanliness.

### Step 3c — Run kb-dedupe (Work section only)

1. Read `~/.cursor/skills/kb-dedupe/SKILL.md`.
2. Execute ONLY its `## Work` section (runs `dedupe.py --json`, writes `proposals/dedupe-*.md` only if `pair_count > 0`).
3. Capture the JSON counters line it prints.

On error: jump to Step 9a.

### Step 3d — Run kb-reorganize (Work section only)

1. Read `~/.cursor/skills/kb-reorganize/SKILL.md`.
2. Execute ONLY its `## Work` section (runs `reorganize.py --json`, writes `proposals/reorganize-*.md` only if `candidate_count > 0`). Step 2 of the kb-reorganize Work section requires the agent to actually read each candidate note and draft a subnote carve-up — do not skip this judgement step; if time-constrained, record only the candidate list and note "subnote carve-up deferred to next pass" in the proposal.
3. Capture the JSON counters line it prints.

On error: jump to Step 9a.

### Step 3e — Run kb-linkrot (Work section only)

1. Read `~/.cursor/skills/kb-linkrot/SKILL.md`.
2. Execute ONLY its `## Work` section. The skill (a) classifies URLs via `linkrot.py`, (b) HEADs public URLs in parallel, (c) resolves Confluence URLs via Atlassian MCP, (d) flags internal `*.rbx.com` URLs as unchecked. Writes `proposals/linkrot-*.md` if anything broken or any internal URLs are listed.
3. Capture the JSON counters line it prints.

On error: jump to Step 9a. If the Atlassian MCP is unavailable, the Confluence pass degrades to "internal-not-checked" treatment — note this in the log and continue; do not abort the sweep over MCP flakiness.

### Step 3f — Run kb-archive (Work section only)

1. Read `~/.cursor/skills/kb-archive/SKILL.md`.
2. Execute ONLY its `## Work` section (runs `archive.py --json`, writes `proposals/archive-*.md` only if `move_candidate_count + ambiguous_count > 0`). Phase 3 is propose-only; no `git mv` runs here.
3. Capture the JSON counters line it prints.

On error: jump to Step 9a.

### Step 3g — Run kb-reindex (Work section only — AUTO-APPLY)

1. Read `~/.cursor/skills/kb-reindex/SKILL.md`.
2. Execute ONLY its `## Work` section. This is the **one** maintenance sub-skill that auto-writes during the sweep. It rewrites only the content between `<!-- KB-GENERATED: inventory begin -->` and `... end -->` in each `_Index.md`. Prose outside the markers is byte-for-byte preserved.
3. Capture the JSON counters line it prints.

On error: jump to Step 9a. If the idempotency check in Step 3 of kb-reindex fails (i.e., a second pass would change things), ABORT — this is a writer bug and must not be papered over.

### Step 4 — Regenerate manifest

```bash
python3 00-Meta/Scripts/manifest.py
```

### Step 5 — Aggregate proposals

Collect up to eight kinds of per-skill proposal files that may have been written this sweep or since the last sweep:

- `proposals/integrity-*.md` (from Step 3 — always this-sweep)
- `proposals/staleness-*.md` (from Step 3b — always this-sweep)
- `proposals/dedupe-*.md` (from Step 3c — always this-sweep)
- `proposals/reorganize-*.md` (from Step 3d — always this-sweep)
- `proposals/linkrot-*.md` (from Step 3e — always this-sweep)
- `proposals/archive-*.md` (from Step 3f — always this-sweep)
- `proposals/ingest-spec-stubs-*.md` (from earlier `ingest-spec` runs between sweeps — carry-forward)
- `proposals/ingest-pr-stubs-*.md` (from earlier `ingest-pr` runs between sweeps — carry-forward)

Note that `kb-reindex` (Step 3g) does NOT produce a proposal file — its auto-apply writes are captured in the commit diff directly.

If any of the above exist, produce a single `00-Meta/Maintenance/proposals/weekly-$(date -u +%F).md` with this structure:

```markdown
---
type: index
schema_version: 1
proposal_kind: weekly
generated_at: <ISO-8601-UTC>
---

## Summary

| skill         | auto-applied                                                 | proposals | counters                                      |
| ------------- | ------------------------------------------------------------ | --------- | --------------------------------------------- |
| kb-integrity  | <n>                                                          | <0-or-1>  | <remaining JSON>                              |
| kb-freshness  | 0                                                            | <0-or-1>  | stale=<n>, missing=<n>                        |
| kb-dedupe     | 0                                                            | <0-or-1>  | pairs=<n>                                     |
| kb-reorganize | 0                                                            | <0-or-1>  | candidates=<n>, suppressed=<m>                |
| kb-linkrot    | 0                                                            | <0-or-1>  | urls=<n>, broken_public=<n>, internal=<n>     |
| kb-archive    | 0                                                            | <0-or-1>  | move_candidates=<n>, ambiguous=<m>            |
| kb-reindex    | <m>                                                          | 0 (auto)  | indexes=<n>, changed=<m>, idempotent=<bool>   |
| ingest-spec   | (write-time; counted here only if carry-forward stubs exist) | <0-or-1>  | files=<n>                                     |
| ingest-pr     | (write-time; counted here only if carry-forward stubs exist) | <0-or-1>  | files=<n>                                     |

## kb-integrity

<body of integrity-*.md under H3 per section>

## kb-freshness

<body of staleness-*.md under H3 per type>

## kb-dedupe

<body of dedupe-*.md under H3 per pair>

## kb-reorganize

<body of reorganize-*.md under H3 per candidate>

## kb-linkrot

<body of linkrot-*.md under H3 per broken URL class>

## kb-archive

<body of archive-*.md under H3 per candidate>

## Carry-forward: ingest-spec stubs

<one H3 per carry-forward ingest-spec-stubs-*.md; include its spec_note frontmatter and the full body>

## Carry-forward: ingest-pr stubs

<one H3 per carry-forward ingest-pr-stubs-*.md; include its pr_url frontmatter and the full body>
```

Delete each per-skill proposal file after incorporating it into the weekly rollup — one artifact per sweep is the whole point.

If no proposal files exist at all, skip creating the rollup file and note "no proposals this week" in the log.

### Step 6 — Log

Append `00-Meta/Maintenance/logs/$(date -u +%F)-kb-weekly.md`:

```markdown
# kb-weekly run $(date -u +%F)

- started: <ISO-8601-UTC>
- finished: <ISO-8601-UTC>

## Per-step counters

- kb-integrity:  <JSON counters captured in Step 3>
- kb-freshness:  <JSON counters captured in Step 3b>
- kb-dedupe:     <JSON counters captured in Step 3c>
- kb-reorganize: <JSON counters captured in Step 3d>
- kb-linkrot:    <JSON counters captured in Step 3e>
- kb-archive:    <JSON counters captured in Step 3f>
- kb-reindex:    <JSON counters captured in Step 3g>

## Notes

<one line per commit-worthy observation; leave empty if nothing noteworthy>
```

### Step 7 — Update `last-run.yaml`

Edit `00-Meta/Maintenance/last-run.yaml` in place. Every stanza below gets `last_run_at: $(date -u +%FT%TZ)`:

- `kb-weekly` — set outcome; update the aggregate counters.
- `kb-integrity` — copy counters from the integrity JSON into its matching keys (`auto_fixed`, `proposals_created`, `outcome`).
- `kb-freshness` — copy `stale` into `stale_flagged`; `outcome` is `clean` if `stale == 0 && missing_date == 0` else `proposals_created`.
- `kb-dedupe` — copy `pairs` into `merge_proposals`; `outcome` is `clean` if `pairs == 0` else `proposals_created`.
- `kb-reorganize` — copy `candidates` into `promotion_proposals`; `outcome` is `clean` if `candidates == 0` else `proposals_created`.
- `kb-linkrot` — copy `urls` into `urls_checked`, `broken_public + broken_confluence` into `urls_broken`; `outcome` is `clean` if `urls_broken == 0` else `proposals_created`.
- `kb-archive` — copy `move_candidates + ambiguous` into `proposals_created`; `archived` stays 0 in Phase 3; `outcome` is `clean` if both counts are 0 else `proposals_created`.
- `kb-reindex` — copy `changed` into `changed_count`; `outcome` is `clean` if `changed == 0` else `auto_applied`.

A `kb-weekly` key will need to be added to `last-run.yaml` if it doesn't exist yet. A `kb-reindex` key may also need to be added on first Phase 3 sweep (the Phase 2 `last-run.yaml` predates `kb-reindex`). Use these templates:

```yaml
kb-weekly:
  last_run_at:
  outcome:
  integrity_auto_fixed: 0
  freshness_stale: 0
  dedupe_pairs: 0
  reorganize_candidates: 0
  linkrot_broken: 0
  archive_proposals: 0
  reindex_changed: 0
  weekly_proposal_written: false

kb-reindex:
  last_run_at:
  outcome:
  changed_count: 0
```

### Step 8 — Commit

```bash
git add -A
git commit -m "kb-weekly: integrity=<n> stale=<n> dedupe=<n> reorg=<n> linkrot=<n> archive=<n> reindex=<n> weekly=<yes|no>" \
           -m "<body listing changed notes; mention whether proposals/weekly-*.md was created and what kb-reindex auto-applied>"
```

### Step 9 — Release lock

```bash
rm 00-Meta/.lock
unset KB_DRIVEN_BY
```

### Step 9a — Abort path (on any error)

```bash
git reset --hard HEAD        # discard any partially applied changes
rm -f 00-Meta/.lock
unset KB_DRIVEN_BY
```

Report the error to the user with the step number that failed and the sub-skill's JSON counters (if any) so the failure is diagnosable.

## Invariants

- **Exactly one commit per successful run**, titled `kb-weekly: ...`. Never mix with hand edits.
- **Exactly one aggregated proposal file per run**, even if multiple sub-skills produced proposals (Phase 2/3). Sub-skills' individual proposal files are merged and deleted.
- **No-op is fine.** A sweep that finds nothing to fix still writes a log entry and updates `last-run.yaml`; it does not need to produce a commit if nothing changed.
