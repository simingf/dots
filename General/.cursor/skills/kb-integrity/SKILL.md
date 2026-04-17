---
description: Verify the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Checks for duplicate names, dangling [[wikilinks]], asymmetric bidirectional edges, schema conformance, and leaks of first-person or conversation IDs. Auto-repairs missing inverse edges; proposes the rest to 00-Meta/Maintenance/proposals/. Use when the user asks to check, audit, verify, or repair the vault, or when running periodic maintenance.
globs:
alwaysApply: false
---

# kb-integrity

Run the five invariant checks in `00-Meta/Scripts/integrity.py`, auto-repair what is safe, propose the rest.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` — the umbrella has already done them.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-integrity $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Schema.md` and `00-Meta/Maintenance/README.md` to refresh on auto-apply vs. propose-for-review policy.

## Work

### 1. Run the checker in auto-repair mode

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/integrity.py --fix-auto --json > /tmp/kb-integrity.json
cat /tmp/kb-integrity.json
```

`integrity.py` auto-repairs **only** missing inverse edges (check #3 — `asymmetric_edges`). The other four checks are reported but not mutated:

- `duplicate_names` — two notes sharing a `name:` collide on bare `[[wikilinks]]`. Never auto-rename.
- `dangling_links` — a `[[target]]` that resolves to nothing. Could be a typo, a missing stub, or a renamed note. Human judgment required.
- `schema_conformance` — missing `type:` or `schema_version:`. These should have been caught at write time; escalate.
- `leaks` — first-person prose, UUIDs, `convo-id` tokens. Rewrite requires judgment.

### 2. Classify what remains

Parse `/tmp/kb-integrity.json`:

- `report.fixed.asymmetric_edges` — auto-repaired. Record the count.
- `report.checks.asymmetric_edges` — asymmetries the auto-fixer refused (inline scalar target fields, unparseable frontmatter). Send to proposals.
- `report.checks.{duplicate_names,dangling_links,schema_conformance,leaks}` — always propose.

### 3. Write the proposal (if anything to propose)

If ANY non-empty array remains under `checks`, write:

```
00-Meta/Maintenance/proposals/integrity-YYYY-MM-DD.md
```

Format:

```markdown
---
type: index
schema_version: 1
proposal_kind: integrity
generated_at: <ISO-8601-UTC>
---

## Summary

- auto-fixed (asymmetric edges): <n>
- duplicate names: <n>
- dangling links: <n>
- schema violations: <n>
- leaks: <n>

## Duplicate Names

For each entry in `checks.duplicate_names`, one bullet: `- name "<name>" appears at: <paths>`. Propose a resolution: rename one file (prefer the less-linked one), add `aliases: [<old-name>]` to the kept file.

## Dangling Links

For each entry in `checks.dangling_links`, one bullet: `- [[<target>]] from <src_path> field <field>`. Propose: likely rename → <candidate>, or create stub at <predicted-path>.

## Schema Violations

For each, list the path and the missing field.

## Leaks

For each, list the path, kind, and the offending line (read from the file; do not guess).
```

Never silently edit the user's prose to fix a leak — every leak fix is a proposal.

### 4. Emit counters

Print one JSON line to stdout:

```json
{"skill":"kb-integrity","auto_fixed":<n>,"proposals":<0-or-1>,"remaining":{"dupes":<n>,"dangling":<n>,"schema":<n>,"leaks":<n>}}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Regenerate manifest.** `python3 00-Meta/Scripts/manifest.py`.
2. **Log.** Append one line to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-integrity.md` with the same JSON counters.
3. **Update `last-run.yaml`** — set `kb-integrity.last_run_at` to `$(date -u +%FT%TZ)`, `kb-integrity.outcome` to `clean` if `remaining` is all zeros else `proposals_created`, and `kb-integrity.auto_fixed` / `kb-integrity.proposals_created`.
4. **Commit.**
   ```bash
   git add -A
   git commit -m "kb-integrity: auto-fixed <n>, proposals <0|1>" -m "<body listing changed notes>"
   ```
5. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- If the scripts crash, leave the tree untouched, release the lock, surface the stack trace to the user.
- If `--fix-auto` appended a duplicate inverse (rare race), a second run of `kb-integrity` is idempotent — the check finds the edge symmetric and does nothing.
