---
description: Execute an approved .apply.yaml sidecar proposal against the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Reads checkbox state from the paired proposal .md, invokes 00-Meta/Scripts/apply.py which runs ops transactionally with integrity-gated rollback, and commits the result in a single batch. Use when the user says "apply this proposal", references a file under 00-Meta/Maintenance/proposals/, or wants to execute reviewed maintenance actions (merges, archival moves, freshness bumps, broken-URL removal, hub promotions, stub creation).
globs:
alwaysApply: false
---

# kb-apply

Thin wrapper around `00-Meta/Scripts/apply.py`. All ops logic, rollback, and integrity gating live in the script; this skill's job is to pick the proposal, confirm with the user, invoke the runner, and commit.

**Core invariant**: every write to the vault that comes out of a maintenance skill flows through a sidecar + `apply.py`. Hand-editing frontmatter to apply a proposal is permitted for emergencies but bypasses the rollback guarantee — prefer this skill.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` (the umbrella handles locking and the clean-tree check).

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-apply $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not — `apply.py`'s rollback depends on being able to reset clean.
3. Read `00-Meta/Maintenance/proposal-format.md` (schema + op semantics + checkbox grammar) if you haven't in this session. The user may ask why an op was or wasn't proposed; the spec is the authoritative answer.

## Work

### 1. Resolve the proposal

Accept either a direct path from the user or a skill name to discover the latest:

- **direct**: user says "apply `00-Meta/Maintenance/proposals/dedupe-2026-04-17.md`".
- **by skill**: user says "apply the latest dedupe proposal" → `ls -t 00-Meta/Maintenance/proposals/<kb>-*.md | head -1`.

The paired sidecar lives at `<proposal>.apply.yaml` (same stem with `.apply.yaml` appended after dropping `.md`, or `<stem>.apply.yaml` — `apply.py` tries both). If no sidecar exists, fail fast: `apply.py` will say "sidecar not found" and the user should re-run the upstream skill with `--emit-sidecar`.

### 2. Dry-run first, always

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/apply.py <proposal.md> --dry-run --json > /tmp/kb-apply.dryrun.json
python3 00-Meta/Scripts/apply.py <proposal.md> --dry-run
```

The human-readable output lists:

- `actions: <checked>/<total> checked` — verify this matches the user's expectation. A typo in a checkbox or a stale proposal often shows up as "0/N checked".
- `> would apply: <id> (<op>)` — one line per action that will fire.
- `. skipped (unchecked): <id>` — one line per unchecked action.
- `ROLLED BACK: <reason>` — dry-run shouldn't roll back, but if the sidecar schema is invalid this is where it surfaces. Abort.

### 3. Confirm with the user

Before calling `apply.py` without `--dry-run`, tell the user:

- proposal path
- source skill + generated_at
- N of M actions will fire
- the first 5 action ids + ops (truncated if more)
- whether any `git_mv` or `create_note` is in the batch (these touch the filesystem, not just frontmatter — higher blast radius)

Wait for "go" unless `KB_DRIVEN_BY=kb-weekly` or the sidecar is from `kb-archive` with `auto_apply: true`.

### 4. Execute

```bash
python3 00-Meta/Scripts/apply.py <proposal.md> --json > /tmp/kb-apply.result.json
```

Read the JSON. Two success modes:

- `rolled_back: false` and `results: [...]` — every checked op applied. `post_violations` should equal `pre_violations` (or be lower).
- `rolled_back: true` and `error: <msg>` — one op failed, the runner restored the snapshot, no files changed. Report the error to the user; the proposal remains actionable after investigation.

`apply.py` enforces integrity-gated rollback: if `post_violations > pre_violations`, the batch is reverted even if every op "succeeded" individually. That's the safety net.

### 5. Mark the proposal applied

If the run succeeded, append a footer to the proposal `.md` so re-runs don't re-prompt:

```bash
cat >> <proposal.md> <<EOF

---

**applied at**: $(date -u +%FT%TZ)
**applied by**: kb-apply
**result**: $(jq -r '.results | length' /tmp/kb-apply.result.json) ops applied, pre=$(jq -r .pre_violations /tmp/kb-apply.result.json) post=$(jq -r .post_violations /tmp/kb-apply.result.json)
EOF
```

If rolled back, append a "rolled back" footer with the error instead, and leave the checkboxes untouched so the user can fix and re-run.

### 6. Emit counters

```json
{"skill":"kb-apply","proposal":"<path>","source_skill":"<kb>","checked":<n>,"applied":<m>,"rolled_back":<bool>,"post_violations":<v>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Regenerate manifest.** `python3 00-Meta/Scripts/manifest.py` — required whenever notes move, get created, or change type.
2. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-apply.md`.
3. **Commit.**
   ```bash
   git add -A
   git commit -m "kb-apply: <source-skill> (<m> ops)" \
              -m "proposal: <path>. post-integrity: <v> violations."
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- **Sidecar not found** — upstream skill didn't emit one. Re-run it with `--emit-sidecar`; do not hand-craft a sidecar.
- **Schema validation error** (unknown op, missing required field) — the upstream emitter is buggy; report the field name, do not "fix" the sidecar by editing it.
- **Integrity regression** (`post_violations > pre_violations`) — `apply.py` rolls back automatically. Inspect which op would have introduced the violation (usually a merge or promote that orphans inbound links); refine the proposal and re-run.
- **30-day staleness guard** — `apply.py` refuses sidecars older than 30 days unless `--force` is passed. Regenerate the proposal rather than force; the vault may have moved under it.
- **Partial success, no rollback needed** — impossible by design. Either every checked op committed or none did.

## Non-goals

- **Never edits the sidecar.** Sidecars are emitter outputs; changing them here would diverge the human proposal from the machine plan.
- **Never re-runs upstream skills.** If the proposal is stale, the user re-runs (e.g.) `kb-dedupe`. This skill only consumes.
- **Never bypasses `apply.py`.** All ops logic is centralized there; tempting as it is to patch a single frontmatter by hand, doing so skips the transactional batch and rollback.
- **Never applies unchecked actions.** Checkbox state is authoritative. If the user wants everything applied, they tick every box; there is no `--all` flag.
