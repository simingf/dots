---
description: Interactively bump `last_verified` on stale notes in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Walks one stale note at a time, accepts y/n/s/q, emits a freshness-verify `.apply.yaml` sidecar with only the accepted bumps, then hands off to `kb-apply` for the actual mutations. Use when the user asks to verify, re-verify, bump, or refresh stale notes — distinct from `kb-freshness` (batch-emit) because this is human-in-the-loop per-note.
globs:
alwaysApply: false
---

# kb-verify

Close the freshness loop with a single bounded edit class: `set_frontmatter last_verified = today` per approved note. Every mutation still flows through `apply.py` for transactional safety — this skill is a curator, not an editor.

**Scope invariant**: `kb-verify` only touches `last_verified`. Never tags, links, summary, or anything structural. If a note needs more than a freshness bump, the user routes through `add-to-knowledge-bank` instead.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` — however, `kb-verify` is interactive and is NOT called from `kb-weekly`. It's an optional follow-up after the weekly sweep.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-verify $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not — keeps the `kb-apply` handoff clean.
3. Read `00-Meta/Schema.md` `last_verified` + `00-Meta/Conventions.md` §freshness policy to confirm the threshold (default 180 days) hasn't changed.

## Work

### 1. Pick a threshold

Default: 180 days before today. Override with `--threshold <days>` from the user. Compute the cutoff date:

```bash
cd /Users/sfeng/roblox-obsidian
TODAY=$(date -u +%F)
THRESHOLD_DAYS=${THRESHOLD_DAYS:-180}
CUTOFF=$(python3 -c "from datetime import date,timedelta; print((date.today()-timedelta(days=${THRESHOLD_DAYS})).isoformat())")
```

### 2. List stale notes

```bash
python3 00-Meta/Scripts/vault_query.py --json stale --since "$CUTOFF" > /tmp/kb-verify.json
```

Output: `{since, stale_count, missing_count, stale:[{path,type,last_verified}], missing:[{path,type,...}]}`.

`kb-verify` ignores `missing` (undated notes are a bigger problem — kb-integrity territory). It also ignores notes in `Templates/`, `Projects/Archived/`, and anything with `status: deprecated` (freshness no longer matters).

Filter the list in one pass:

```python
import json
doc = json.load(open('/tmp/kb-verify.json'))
from vault import load_vault, VAULT_ROOT
import os, sys; sys.path.insert(0, '00-Meta/Scripts')
notes = load_vault(VAULT_ROOT)
queue = []
for s in doc['stale']:
    fm = notes[s['path']]['fm']
    if fm.get('status') == 'deprecated': continue
    if s['path'].startswith(('Templates/', 'Projects/Archived/')): continue
    queue.append(s | {
        'owner_team': fm.get('owner_team',''),
        'summary_first_line': (notes[s['path']]['body'].splitlines() or [''])[0][:120],
    })
queue.sort(key=lambda s: s['last_verified'])  # stalest first
```

### 3. Walk each note interactively

For each entry in `queue`, present a compact card:

```
[12/47]  Tools/temporal.md
         type: platform      owner: [[workflow-platform]]
         last_verified: 2025-03-14   (398 days ago)
         summary: Temporal is Roblox's general-purpose durable workflow engine...

         [y]es bump | [n]o (record rejection) | [s]kip | [q]uit
```

Keybinds:

- `y` → append `{id, op:set_frontmatter, path, field:last_verified, value:<today>}` to the accepted list.
- `n` → append to a `rejected:` list in counters (never emits a delete — just surfaces it for human follow-up in a later pass).
- `s` → neither accept nor reject; skipped notes remain stale for the next run.
- `q` → stop the walk immediately; everything accepted so far still goes to the sidecar.

Do NOT batch-approve. The whole point of `kb-verify` (vs `kb-freshness --emit-sidecar`) is that a human has eyes on each note before bumping. If the user wants batch, they use `kb-freshness` + `kb-apply`.

### 4. Emit the sidecar (only if accepted list is non-empty)

```python
import sys; sys.path.insert(0, '00-Meta/Scripts')
from sidecar import emit_sidecar, slugify
actions = []
for a in accepted:
    actions.append({
        "id": f"verify-bump-{slugify(a['path'])}",
        "op": "set_frontmatter",
        "path": a['path'],
        "field": "last_verified",
        "value": today,
        "rationale": f"re-verified interactively (was {a['last_verified']})",
    })
emit_sidecar(
    f"00-Meta/Maintenance/proposals/freshness-verify-{today}.apply.yaml",
    source_skill="kb-verify",
    generated_at=today,
    actions=actions,
)
```

### 5. Write the paired proposal `.md` with every action pre-checked

Because the user explicitly approved each bump in step 3, the checkboxes are pre-ticked. `kb-apply` will honor them as-is.

```
00-Meta/Maintenance/proposals/freshness-verify-$(date -u +%F).md
```

Body:

```markdown
---
type: index
schema_version: 1
proposal_kind: freshness-verify
generated_at: <ISO-8601-UTC>
approved_count: <n>
rejected_count: <m>
skipped_count: <k>
---

## Summary

Human-in-the-loop freshness verification — <n> bumps approved, <m> rejections logged, <k> skipped.

## Proposed actions

- [x] `verify-bump-<slug>` — bump last_verified on <path> (was <old>)
<one per accepted entry>

## Rejected (not bumped — consider deletion in a later pass)

- `<path>` — last_verified <old>; summary: <first-line>
<one per rejected entry>
```

### 6. Hand off to `kb-apply`

If the user confirms, invoke `kb-apply` directly on the new proposal — the skill contract then drives the actual mutation, commit, and manifest regenerate:

```bash
# pseudo: trigger kb-apply on 00-Meta/Maintenance/proposals/freshness-verify-${TODAY}.md
```

Otherwise leave the pair on disk for later review.

### 7. Emit counters

```json
{"skill":"kb-verify","queued":<queue-len>,"approved":<n>,"rejected":<m>,"skipped":<k>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-verify.md`.
2. **No commit here.** The commit happens inside `kb-apply` when the user runs it. `kb-verify` only produces proposal artifacts.
3. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- **No stale notes** — nothing to verify. Write no proposal, emit counters with zeros, release lock, done.
- **User quits mid-walk** — honor it; emit the sidecar with only what was accepted so far. Skipped/unanswered entries stay stale for the next run.
- **Sidecar emit fails** (disk full, path collision with an existing proposal) — abort without writing the `.md`; tell the user which path failed; do not leave a half-baked pair.

## Non-goals

- **Never mutates the vault directly.** All bumps flow through `kb-apply` / `apply.py` for transactional integrity.
- **Never touches fields other than `last_verified`.** Edits to summary, tags, or structural edges belong in `add-to-knowledge-bank`.
- **Never auto-deletes rejected notes.** Rejection is a signal, not a mandate — it goes into the proposal's "Rejected" section for human follow-up.
- **Never runs non-interactively.** There is no `--yes-to-all` flag; that's what `kb-freshness --emit-sidecar` is for.
- **Not a duplicate of `kb-freshness`.** `kb-freshness` emits a batch sidecar with every stale note unchecked (user ticks boxes manually). `kb-verify` is the TTY counterpart — user decides per-note, accepted items pre-checked.
