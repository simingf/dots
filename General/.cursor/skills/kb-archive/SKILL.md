---
description: Propose archival moves for completed projects in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Flags `type: project, status: completed` notes aged >=90 days since their `completed_at` for relocation from `Projects/Completed/` to `Projects/Archived/`, plus ambiguous cases (completed without a date, or active/paused projects stale beyond their threshold). Propose-only in Phase 3 — every `git mv` is human-driven. Use when the user asks "archive old projects", "clean up Projects/", "which projects should be archived", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-archive

Surface completed projects that have been cold long enough to archive. Never runs `git mv` itself — a bad archive move breaks inbound `related_projects` links and the corrective fix is a tangle of retargeting. The user approves each move by hand.

Phase 3 ships propose-only. Auto-apply (behind `archive-config.yaml`) is deferred to Phase 4 after 2-3 months of clean propose-only runs.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly`.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-archive $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `Projects/_Index.md` and `Projects/Archived/_Index.md` to confirm the current archive policy is the one this skill assumes (`status: completed && age >= 90d -> Archived/`).

## Work

### 1. Scan project lifecycle

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/archive.py --json > /tmp/kb-archive.json
```

Output: `{move_candidate_count, ambiguous_count, move_candidates[], ambiguous[]}`.

- `move_candidates`: each has `path`, `name`, `completed_at`, `age_days`, `suggested_dst`.
- `ambiguous`: each has `path`, `name`, `status`, and a `reason` describing why the rule couldn't decide.

### 2. Write the proposal (only if `move_candidate_count + ambiguous_count > 0`)

Filename: `00-Meta/Maintenance/proposals/archive-$(date -u +%F).md`

Body template:

```markdown
---
type: index
schema_version: 1
proposal_kind: archive
generated_at: <ISO-8601-UTC>
move_candidate_count: <n>
ambiguous_count: <m>
threshold_days: 90
---

## Summary

- projects past threshold (>=90d completed): <n>
- ambiguous cases: <m>

## Action

Apply each `git mv` below, then update the moved note's `status: archived` and add `archived_at: $(date -u +%F)` to its frontmatter. Commit with `git commit -m "archive: <slug>"`.

Do NOT rebase inbound links — path-qualified links (`Projects/Completed/foo`) will break. If any inbound link is path-qualified, replace it with the bare name (`[[foo]]`) first; basename-only links follow Obsidian's resolver automatically.

## Move candidates

<one H3 per candidate, sorted by age desc>

### <name>  (<age_days>d since completed_at <completed_at>)

```bash
git mv <path> <suggested_dst>
```

## Ambiguous cases (review and decide)

<one bullet per ambiguous entry>

- `<path>` — status=<status>: <reason>
```

If `move_candidate_count + ambiguous_count == 0`, write NO proposal file. Just emit counters.

### 3. Emit counters

```json
{"skill":"kb-archive","move_candidates":<n>,"ambiguous":<m>,"proposals":<0-or-1>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-archive.md`.
2. **Update `last-run.yaml`** — `kb-archive.last_run_at`, `outcome` (`clean` if both counts 0 else `proposals_created`), `archived` stays 0 (Phase 3 doesn't apply moves), `proposals_created` = proposal count.
3. **Commit (if anything changed — typically `last-run.yaml` and possibly a new proposal).**
   ```bash
   git add -A
   git commit -m "kb-archive: <move_candidates> candidate(s), <ambiguous> ambiguous"
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Non-goals (Phase 3)

- Does not run `git mv`. Phase 4 will auto-apply behind `00-Meta/Maintenance/archive-config.yaml` gating.
- Does not edit any note's `status:` or `archived_at:`. Those are part of the approved human move.
- Does not touch `Projects/_Index.md` or `Projects/Archived/_Index.md`. `kb-reindex` owns directory inventories.
- Does not consider non-project lifecycle (incidents, bugs). Those have different archival rules (if any) and are scoped out.

## Configuration placeholder

`00-Meta/Maintenance/archive-config.yaml` will gate Phase 4 auto-apply. Its shape (for reference, not in effect yet):

```yaml
auto_apply: false           # flip to true once propose-only has been clean for 60+ days
threshold_days: 90
destination: Projects/Archived
also_set_frontmatter_status: archived
also_stamp_archived_at: true
```
