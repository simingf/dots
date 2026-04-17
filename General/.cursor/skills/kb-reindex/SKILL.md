---
description: Regenerate the auto-generated `## Inventory` section of every `_Index.md` in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Rewrites only content strictly between `<!-- KB-GENERATED: inventory begin -->` / `... end -->` markers — hand-curated sections (Purpose, Conventions, Notable Notes, Relevant Bases, See Also) are untouched. Auto-applies (bounded edit scope makes accidental damage impossible). Use when the user asks to "regenerate indexes", "rebuild the index files", "refresh _Index.md inventories", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-reindex

Keep every directory's `_Index.md` in sync with the notes living under it, without trampling the hand-curated prose that explains each directory.

This is the one auto-apply maintenance skill Phase 3 introduces. Safety comes from strict edit-scope bounding: the skill only rewrites content between two markers, and refuses to run on any `_Index.md` missing markers until the markers have been seeded (either by this skill's first run or by a hand edit).

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly`.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-reindex $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/AGENTS.md` §7 (standard `_Index.md` format).

## Work

### 1. Dry-run first (Phase 3 discipline — audit before rewrite)

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/reindex.py --check --today $(date -u +%F)
echo "exit=$?"
```

If exit is 0, nothing to do — skip straight to Step 3 and emit counters with `changed_count: 0`.

If exit is 1, continue to Step 2.

### 2. Apply the rewrite

```bash
python3 00-Meta/Scripts/reindex.py --today $(date -u +%F) --json > /tmp/kb-reindex.json
```

This writes every `_Index.md` whose `## Inventory` block is out of date. It:

- Only touches files literally named `_Index.md` (the root `00-Index.md`, `00-Meta/AGENTS.md`, `00-Meta/Schema.md`, `CHANGELOG.md`, `Glossary.md`, and Maintenance/README.md are curated hubs, not auto-generated — they're excluded by filename).
- Rewrites only content between `<!-- KB-GENERATED: inventory begin -->` and `<!-- KB-GENERATED: inventory end -->`. Prose outside those markers is byte-for-byte preserved.
- Inserts the markers just before `## See Also` (or at EOF) if missing.
- Bumps `last_rebuilt:` in the frontmatter to today.

### 3. Verify idempotency

```bash
python3 00-Meta/Scripts/reindex.py --check --today $(date -u +%F)
echo "exit=$?"
```

Expect exit 0. If exit 1, the writer has a bug — abort and report; do NOT run a second write pass or you risk a flip-flop.

### 4. Emit counters

```json
{"skill":"kb-reindex","index_count":<n>,"changed":<m>,"idempotent":true}
```

`changed` is the `changed_count` from the first-pass output. `idempotent` is the result of step 3.

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-reindex.md`.
2. **Update `last-run.yaml`** — `kb-reindex.last_run_at`, `outcome` (`clean` if `changed == 0` else `auto_applied`), `changed_count`.
3. **Commit (only if `changed > 0`).**
   ```bash
   git add -A
   git commit -m "kb-reindex: refreshed <m> _Index.md inventory section(s)"
   ```
   Use `-A` so the frontmatter `last_rebuilt:` bump and the inventory section are captured together. If `changed == 0`, still update `last-run.yaml` and commit that single-line bump — the audit trail matters.
4. **Release lock.** `rm 00-Meta/.lock`.

## Adding `kb-reindex` to `last-run.yaml`

If this skill runs before `last-run.yaml` has a `kb-reindex:` stanza, add it with these keys:

```yaml
kb-reindex:
  last_run_at:
  outcome:
  changed_count: 0
```

## Non-goals

- kb-reindex never touches any file outside `_Index.md`. The filename filter is load-bearing; do not extend it to include other `type: index` notes.
- kb-reindex never rewrites content outside the `KB-GENERATED` markers. Not "usually" — never. If the user wants a new standard section added to every `_Index.md`, that's a hand edit to each file (or a one-off migration script under `00-Meta/Migrations/`), not a kb-reindex extension.
- kb-reindex never deletes an `_Index.md`. An empty directory still gets an index note with an empty inventory table; the "is this dir still relevant?" call belongs to the user, not to this skill.
- kb-reindex never alters the order of child directories or the counts in `_Index.md` frontmatter keys like `covers_types:`. Those are a human-curated signal.
