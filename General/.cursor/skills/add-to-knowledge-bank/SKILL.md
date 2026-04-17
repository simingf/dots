---
description: Distill the current Cursor conversation's learnings into the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Use at the end of any session where the user investigated a service, DAG, workflow, Temporal workflow, table, Kafka topic, bug, incident, platform, tool, library, concept, or internal process and wants the knowledge captured. Creates or updates type-correct notes, wires bidirectional links, never links back to the conversation itself.
globs:
alwaysApply: false
---

# add-to-knowledge-bank

Turn the current conversation into durable notes in `/Users/sfeng/roblox-obsidian`.

## Hard rules (non-negotiable)

1. **No conversation IDs, UUIDs, timestamps, or transcript links** anywhere in the note body or frontmatter. See `[[0006-no-cursor-convo-linking]]`.
2. **No first-person prose** ("I tried", "my run"). Write in neutral third person.
3. **Never invent data.** Only record facts the user established in this session or that are already in the vault / provable by the live tools you used (Sourcegraph, Confluence, code reading, tool output).
4. **Type-correct notes only.** Every note has `type:` from `00-Meta/Schema.md` and lives in the directory that type mandates. No orphan types.
5. **Bidirectional links.** Every structural edge you write is mirrored on the target note per `Schema.md` §relationship_pairs. Use `python 00-Meta/Scripts/integrity.py --fix-auto` at the end to confirm.

## Preflight

1. **Lock.** Acquire `/Users/sfeng/roblox-obsidian/00-Meta/.lock`:
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "add-to-knowledge-bank $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
   If `KB_DRIVEN_BY=kb-weekly` is set, skip this step — the umbrella holds the lock.
2. **Clean tree.** Verify `git status --porcelain` is empty. If not, report the dirty state and abort — writing on top of uncommitted user changes corrupts lineage.
3. **Read the contract.** Read these three files (top-to-bottom) before any write:
   - `00-Meta/Schema.md` (types, fields, relationship pairs)
   - `00-Meta/Conventions.md` (naming, tag vocabulary, link hygiene)
   - `00-Meta/AGENTS.md` §4 (navigation ladder) and §5 (write protocol)

If `KB_DRIVEN_BY=kb-weekly`, the umbrella has already done (1) and (2); still do (3).

## Work

### 1. Extract entities from the conversation

Make a flat list of every concrete resource discussed. For each entity, record:

| column      | value                                                                                                             |
| ----------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`      | canonical name (kebab-case for services, PascalCase for workflows, etc. per `Conventions.md` §Naming Conventions) |
| `type`      | one of the 27 types in `Schema.md`                                                                                |
| `new_facts` | bullet list of facts the user just learned or confirmed                                                           |
| `edges`     | every `field: [[target]]` edge implied by the new facts                                                           |

Aim for ~5-15 entities per conversation. If the list is larger than 15, the conversation probably covered multiple topics — split it and run this skill twice.

**Symptom signatures for bugs.** If one of the entities is `type: bug`, compute the canonical signature:

```bash
echo "<error text>" | python3 00-Meta/Scripts/symptom_sig.py --json
```

Copy the resulting `message`, `frames`, and `key` into the bug note's `symptom_signature:` block. Do NOT wedge raw timestamps or UUIDs into the signature.

### 2. Locate existing notes

Use the navigation ladder to resolve each entity to its existing note, if any:

```bash
jq --arg n "<name>" '.notes[] | select(.name==$n or (.aliases // []) | index($n))' 00-Meta/vault-index.json
```

If the entity does not exist, pick the right directory from `Schema.md` §types and pick a template from `00-Meta/Templates/<type>.md` as the starting skeleton.

### 3. Write or update notes

For each entity:

- **Update existing.** Patch the frontmatter arrays (append-only; do not reorder or delete existing entries without explicit user direction). Add new prose under the appropriate H2 section. If the relevant H2 does not exist, create it using the template's section ordering.
- **Create new.** Copy `00-Meta/Templates/<type>.md` to the target path; fill in every required scalar (`name`, `status`, `schema_version`, `last_verified`, `owner_team` where applicable); write a concise `## Overview` (2-4 sentences) and the type-specific H2s from the template. Set `last_verified:` to today (UTC, `YYYY-MM-DD`).

**Array caps.** If any array is about to exceed 20 entries, stop appending and instead write `<field>_overflow_to: "[[Bases/<appropriate-base>]]"` if not already set; explain in the commit body.

**Tags.** Only from `00-Meta/Conventions.md` §Controlled Tag Vocabulary. Adding a tag not on the list means first editing `Conventions.md` to reserve it.

### 4. Wire bidirectional links

For every edge `<src> --<field>--> <tgt>` you just wrote:

1. Look up the inverse field in `Schema.md` §relationship_pairs (or in the inverse map in `00-Meta/Scripts/vault.py`).
2. Open `<tgt>` and append `[[<src>]]` to the inverse field, respecting the same array cap rule.

Common pairs to not miss:

- `calls_services` ↔ `called_by_services`
- `triggers_workflows` ↔ `triggered_by_workflows`
- `reads_tables` / `writes_tables` ↔ `read_by` / `written_by`
- `produces_topics` / `consumes_topics` ↔ `produced_by` / `consumed_by`
- `uses_platforms` ↔ `hosts`
- `owner_team` ↔ `owns_<plural-type>`
- `related_projects` (on any resource) ↔ `touches_<plural-type>` / `specs` / `related_bugs` / `related_incidents` (on the project)

### 5. Emit counters

Print one final JSON line to stdout so the umbrella can aggregate when driven by `kb-weekly`:

```json
{"skill":"add-to-knowledge-bank","created":<n>,"updated":<n>,"edges_added":<n>,"errors":<n>}
```

## Finalize

Skip all steps in this section when `KB_DRIVEN_BY=kb-weekly` — the umbrella handles them.

1. **Integrity check.** Run `python3 00-Meta/Scripts/integrity.py --fix-auto`. Every remaining issue must be resolved by further edits (never by ignoring or suppressing).
2. **Regenerate manifest.** `python3 00-Meta/Scripts/manifest.py` — this updates `00-Meta/vault-index.json`.
3. **Log.** Append a one-line summary to `00-Meta/Maintenance/logs/$(date -u +%F)-add-to-knowledge-bank.md` listing touched notes by relative path, grouped by `created:` vs. `updated:`.
4. **Commit.** `git add -A && git commit -m "add-to-knowledge-bank: <n> notes (<short topic>)"` with a body that lists every changed note path.
5. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- If integrity reports issues you can't fix, leave the work uncommitted (so the user can inspect) and release the lock; do NOT commit a broken vault.
- If you touched a note outside the intended entity set, that is a bug in entity extraction — revert the stray edit before committing.
