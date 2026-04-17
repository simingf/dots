---
description: Archive completed projects in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Flags `type: project, status: completed` notes aged >=90 days since their `completed_at` for relocation from `Projects/Completed/` to `Projects/Archived/`. Phase 4: auto-applies rule-passing moves via `kb-apply` when `archive-config.yaml :: auto_apply: true`; still propose-only for ambiguous cases. Use when the user asks "archive old projects", "clean up Projects/", "which projects should be archived", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-archive

Surface completed projects that have been cold long enough to archive, and — when the config flag allows — actually move them. Every `git mv` is still routed through `apply.py`'s op library so integrity is checked + rollback is possible. Ambiguous cases always produce a proposal `.md` for human review.

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

### 1. Scan project lifecycle + emit sidecar

```bash
cd /Users/sfeng/roblox-obsidian
TODAY=$(date -u +%F)
python3 00-Meta/Scripts/archive.py --json \
  --emit-sidecar "00-Meta/Maintenance/proposals/archive-${TODAY}.apply.yaml" \
  > /tmp/kb-archive.json
```

Output: `{move_candidate_count, ambiguous_count, move_candidates[], ambiguous[]}`. Every rule-passing candidate becomes a triplet in the sidecar: `git_mv` + `set_frontmatter status=archived` + `set_frontmatter archived_at=<today>`.

### 2. Consult `archive-config.yaml` for auto-apply gating

```bash
AUTO_APPLY=$(python3 -c "
import re
with open('00-Meta/Maintenance/archive-config.yaml') as f:
    txt = f.read()
m = re.search(r'^\s*auto_apply:\s*(\S+)', txt, re.MULTILINE)
print('true' if m and m.group(1).strip().lower() == 'true' else 'false')
")
```

- If `AUTO_APPLY=true` **and** `move_candidate_count > 0`: write a machine-generated `archive-${TODAY}.md` with every action id pre-checked (see step 3), then hand it to `kb-apply` and commit. Ambiguous cases still go into the human review section — if `ambiguous_count > 0`, the same `.md` carries that section and `kb-apply` naturally ignores unchecked items.
- If `AUTO_APPLY=false`: write the same `.md` with every action id **unchecked** so the human decides per-candidate.

### 3. Write the proposal (only if `move_candidate_count + ambiguous_count > 0`)

Filename: `00-Meta/Maintenance/proposals/archive-$(date -u +%F).md`

Body template:

````markdown
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

Tick each checkbox below whose move you approve, then run `kb-apply` on this proposal. `kb-apply` dispatches `git_mv` + `set_frontmatter` ops atomically.

Do NOT rebase inbound links — path-qualified links (`Projects/Completed/foo`) will break. If any inbound link is path-qualified, replace it with the bare name (`[[foo]]`) first; basename-only links follow Obsidian's resolver automatically.

## Proposed actions

- [ ] `archive-mv-<slug>` — git mv <path> -> <suggested_dst>  (<age_days>d completed)
- [ ] `archive-status-<slug>` — set status=archived at <suggested_dst>
- [ ] `archive-stamp-<slug>` — set archived_at=<today> at <suggested_dst>

<one triplet per move_candidate; if AUTO_APPLY=true, all boxes pre-checked>

## Move candidates (diagnostics)

<one H3 per candidate, sorted by age desc>

### <name> (<age_days>d since completed_at <completed_at>)

- sidecar action ids: `archive-mv-<slug>`, `archive-status-<slug>`, `archive-stamp-<slug>`
- from: `<path>`
- to: `<suggested_dst>`
````

## Ambiguous cases (review and decide)

<one bullet per ambiguous entry>

- `<path>` — status=<status>: <reason>

````

If `move_candidate_count + ambiguous_count == 0`, write NO proposal file. Just emit counters.

### 4. If AUTO_APPLY=true, run kb-apply immediately

```bash
if [ "$AUTO_APPLY" = "true" ] && [ "$MOVE_COUNT" -gt 0 ]; then
  python3 00-Meta/Scripts/apply.py "00-Meta/Maintenance/proposals/archive-${TODAY}.md" --json \
    > /tmp/kb-archive-apply.json
fi
```

`apply.py` honours the checkbox grammar, so pre-checking the action ids in step 3 is sufficient. On any integrity degradation or op failure, the batch rolls back and `kb-archive` reports it — the proposal file remains for post-mortem review.

### 5. Emit counters

```json
{"skill":"kb-archive","move_candidates":<n>,"ambiguous":<m>,"auto_applied":<bool>,"proposals":<0-or-1>}
````

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

## Non-goals

- Does not run `git mv` directly — always routes through `apply.py`'s `git_mv` op so integrity is checked and rollback is possible.
- Does not touch ambiguous cases automatically; they always require human review regardless of `auto_apply`.
- Does not touch `Projects/_Index.md` or `Projects/Archived/_Index.md`. `kb-reindex` owns directory inventories.
- Does not consider non-project lifecycle (incidents, bugs). Those have different archival rules (if any) and are scoped out.

## Configuration

`00-Meta/Maintenance/archive-config.yaml` gates the auto-apply flip. Current shape:

```yaml
auto_apply: true # set to false to force propose-for-review mode
threshold_days: 90
destination: Projects/Archived
also_set_frontmatter_status: archived
also_stamp_archived_at: true
```
