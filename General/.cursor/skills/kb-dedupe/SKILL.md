---
description: Detect probable-duplicate notes in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Intra-type pairwise comparison via name/alias token overlap, H2 section overlap, and difflib body similarity. Propose-only — never auto-merges. Use when the user asks "find duplicates", "dedupe the vault", "are there near-duplicates", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-dedupe

Surface note pairs that look like duplicates within the same `type:`. Never auto-merges — a wrong merge corrupts link topology and is hard to undo. This skill writes one proposal markdown per run; the user reviews, picks a survivor, merges, and commits by hand (or with `add-to-knowledge-bank`'s help).

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly`.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-dedupe $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Schema.md` §types (duplicates must respect type partitioning) and `00-Meta/Conventions.md` §Link Hygiene (how to add aliases + redirects).

## Work

### 1. Run the duplicate detector + emit sidecar

```bash
cd /Users/sfeng/roblox-obsidian
TODAY=$(date -u +%F)
python3 00-Meta/Scripts/dedupe.py --json \
  --emit-sidecar "00-Meta/Maintenance/proposals/dedupe-${TODAY}.apply.yaml" \
  > /tmp/kb-dedupe.json
```

Reports `pair_count` and `pairs[]` with per-pair scores (`name_overlap`, `h2_overlap`, `body_ratio`). Intra-type only. Each flagged pair also becomes a `merge_note` action in the emitted `.apply.yaml` sidecar (see `00-Meta/Maintenance/proposal-format.md`).

### 2. Write the paired proposal markdown (only if `pair_count > 0`)

```
00-Meta/Maintenance/proposals/dedupe-$(date -u +%F).md
```

Body template:

```markdown
---
type: index
schema_version: 1
proposal_kind: dedupe
generated_at: <ISO-8601-UTC>
pair_count: <n>
---

## Summary

- candidate duplicate pairs: <n>

## Action

For each flagged pair, the sidecar emits a `merge_note` action with `source = a_path` and `target = b_path`. To apply, tick the checkbox below and run `kb-apply`. To swap survivor, edit the sidecar and flip `source`/`target`. To abandon a pair, leave the checkbox unchecked.

## Proposed actions

- [ ] `merge-<a-slug>-into-<b-slug>` — <type>: <a_name> -> <b_name> (ratio=<body_ratio>)

## Candidate pairs (diagnostics)

<one H3 per pair, sorted by body_ratio descending>

### <type>: <a_name> <-> <b_name>

- sidecar action id: `merge-<a-slug>-into-<b-slug>`
- a: `<a_path>`
- b: `<b_path>`
- name_overlap: <x>
- h2_overlap: <x>
- body_ratio: <x>
- suggested survivor: <path-with-more-inbound-links> (agent looks up via jq on vault-index.json)
```

For each flagged pair the skill writes the suggested survivor by counting how many notes link to either side via structural frontmatter fields:

```bash
# pseudo — done once per pair
python3 -c "
from vault import load_vault, WIKILINK_RE, STRUCTURAL_FIELDS
import sys, os
notes, _, basename_index = load_vault()
def count(name):
    n = 0
    for p, info in notes.items():
        if p.startswith('00-Meta/Templates'): continue
        for f, v in info['fm'].items():
            if f not in STRUCTURAL_FIELDS: continue
            vs = v if isinstance(v, list) else [v] if isinstance(v, str) else []
            for item in vs:
                if isinstance(item, str) and name in WIKILINK_RE.findall(item):
                    n += 1
    return n
a, b = sys.argv[1], sys.argv[2]
print('a' if count(a) >= count(b) else 'b', count(a), count(b))
" <a_name> <b_name>
```

### 3. Emit counters

```json
{"skill":"kb-dedupe","pairs":<n>,"proposals":<0-or-1>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-dedupe.md`.
2. **Update `last-run.yaml`** — `kb-dedupe.last_run_at`, `outcome` (`clean` if 0 pairs else `proposals_created`), `merge_proposals` to the pair count.
3. **Commit (if anything changed — typically just `last-run.yaml` and possibly a new proposal).**
   ```bash
   git add -A
   git commit -m "kb-dedupe: <n> candidate pair(s)"
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Non-goals

- kb-dedupe never merges, renames, deletes, or edits note bodies. Every remediation is human-driven.
- kb-dedupe never compares across types — that's a routing question (wrong directory) and belongs to `kb-reorganize` (Phase 3), not here.
