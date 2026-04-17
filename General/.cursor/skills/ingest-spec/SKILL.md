---
description: Ingest a technical specification (Confluence page via MCP or pasted markdown) into the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian as a type:spec note. Extracts a glossary, exact-matches terms to existing vault notes (linked), proposes stubs for unmatched terms (never auto-creates, never writes dangling links), wires bidirectional documented_in/covered_entities edges. Use when the user asks to ingest a spec, parse a Confluence page into the vault, record a design doc, or seed glossary entries from a spec.
globs:
alwaysApply: false
---

# ingest-spec

Convert a technical specification into a `type: spec` note in `/Users/sfeng/roblox-obsidian/Specs/`, carefully linking only to entities that already exist and proposing (not creating) stubs for the rest.

**Core integrity invariant**: this skill never writes a dangling `[[wikilink]]`. Unmatched glossary terms are written as bold plain text (e.g. `**Dedup Window**`) until the user approves a stub via the proposal file. This matches the convention in [Specs/2026-01-opa-temporal-migration-design.md](Specs/2026-01-opa-temporal-migration-design.md).

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` (not typical — ingest-spec is a write-time skill and usually runs independently).

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "ingest-spec $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Schema.md` (types, especially `spec` and the `covered_entities ↔ documented_in` pair at line 98), `00-Meta/Conventions.md` (spec filename is `YYYY-MM-<kebab-slug>.md`; controlled tag vocabulary), `00-Meta/Templates/spec.md` (the target shape).
4. Identify the input:
   - **URL input**: user provides `https://roblox.atlassian.net/wiki/spaces/<SPACE>/pages/<id>/<title>`. Extract the numeric page ID from the URL. Use the Atlassian MCP tool `confluence_get_page` with `page_id` and `convert_to_markdown: true, include_metadata: true`. Source kind is `confluence`.
   - **Pasted markdown**: user pastes the body directly. Source kind is `paste` (or `gdoc` if the user notes the source). Ask the user for title and date if the paste is bare.

## Work

### 1. Normalize input to markdown body + metadata

Regardless of source, end up with:

- `title` (string)
- `publish_date` (YYYY-MM-DD; from Confluence metadata or user-provided for paste)
- `source_url` (URL for Confluence/GDoc inputs; empty for paste)
- `source_kind` (`confluence` | `gdoc` | `paste`)
- `body` (markdown; from MCP's `convert_to_markdown: true`, or the paste as-is)

Derive `name` (filename stem) from title: lowercase, spaces → hyphens, strip punctuation, drop leading articles, prefix with `YYYY-MM-` from `publish_date`. Must match `^\d{4}-\d{2}-[a-z0-9-]+$`. If the derived name collides with an existing file in `Specs/`, append a disambiguating token from the title.

### 2. Extract glossary terms

**Preferred path**: parse the body's `## Glossary` section if present. Each term is the `**bolded**` segment before the em-dash on a bullet line:

```
- **Dedup Window** — The time window within which repeat ids are collapsed.
```

→ term = `Dedup Window`.

**Fallback (no `## Glossary`)**: conservative entity scan over the body:

- find all `**bolded phrases**` that are not inside a code block
- find all `PascalCase` tokens ≥2 words, and `snake.case.tokens`, `kebab-case-tokens` appearing ≥2 times
- drop common English words, drop code identifiers inside backticks

Deduplicate terms (case-insensitively, preserving first-seen casing).

### 3. Classify each term: exact / fuzzy / new

Load the manifest:

```bash
MANIFEST=/Users/sfeng/roblox-obsidian/00-Meta/vault-index.json
```

For each term T:

1. **Exact match** — `jq --arg n "<T>" '.notes[] | select(.name==$n or ((.aliases // [])[]==$n))' $MANIFEST` returns ≥1 note. Also check the normalized form (lowercased, spaces → hyphens) against `.notes[].name`. Pick the first hit; if multiple same-basename hits exist, error out (that's an integrity violation kb-integrity should have caught — abort, do not guess).
2. **Fuzzy match** — no exact hit. Run `difflib.get_close_matches(T, [n['name'] for n in manifest.notes], n=3, cutoff=0.88)`. If any matches, stash them for the proposal.
3. **New** — no matches at either level. Stash for the proposal under "new stubs".

### 4. Write the spec note

Copy [00-Meta/Templates/spec.md](00-Meta/Templates/spec.md) to `Specs/<name>.md`. Fill in:

- frontmatter: `name`, `status: active` (or `draft`/`approved` if the Confluence page's state is clear), `owner_team: "[[<team>]]"` (ask user or infer from Confluence space), `authors_teams`, `tags`, `source_kind`, `source_url`, `publish_date`, `covered_entities` (filled in §5), `last_verified: <today-UTC>`, `sources: [{kind: <source_kind>, url: <source_url>}]`, `external_links.{confluence|gdoc}`.
- body: copy the spec content verbatim into the template's section structure (`## Summary`, `## Glossary`, `## Scope`, `## Proposal`, `## Alternatives Considered`, `## Notes`, `## See Also`). Where sections don't exist in the source, leave the template's stub heading.
- **Glossary section**: rewrite each bullet using the classification — exact matches become `[[wikilink]]`, fuzzy and new stay as `**bold plain text**`. Include the definition text unchanged.
- **Inline references**: in `## Summary`, `## Scope`, `## Proposal`, anywhere the body refers to an exact-matched term, replace the bare form with `[[wikilink]]`. For fuzzy/new terms, wrap in `**bold**` if not already (so the user can grep for promotion later).

### 5. Wire bidirectional edges (exact matches only)

Set `covered_entities:` on the new spec to the list of `[[<name>]]` references for every exact match. For each exact-matched note, append `[[<spec-name>]]` to its `documented_in:` array, respecting the max_entries cap (20) from Schema.md.

### 6. Write the stubs proposal + sidecar (only if fuzzy or new terms exist)

Two paired files — a human `.md` for review and a machine sidecar for `kb-apply`:

```
00-Meta/Maintenance/proposals/ingest-spec-stubs-$(date -u +%F)-<spec-slug>.md
00-Meta/Maintenance/proposals/ingest-spec-stubs-$(date -u +%F)-<spec-slug>.apply.yaml
```

Emit the sidecar via `sidecar.emit_sidecar` directly (the Python helper in `00-Meta/Scripts/sidecar.py`). Each "new stub" becomes a `create_note` action; fuzzy matches are NOT in the sidecar (they're a linking decision, not a creation):

```python
import sys, os
sys.path.insert(0, '00-Meta/Scripts')
from sidecar import emit_sidecar, slugify
actions = []
for stub in new_stubs:  # list of {term, proposed_type, proposed_path}
    actions.append({
        "id": f"create-stub-{slugify(stub['term'])}",
        "op": "create_note",
        "path": stub["proposed_path"],
        "template": stub["proposed_type"],
        "fields": {"name": slugify(stub["term"]), "aliases": [stub["term"]]},
        "rationale": f"referenced by [[{spec_name}]]",
    })
emit_sidecar(
    f"00-Meta/Maintenance/proposals/ingest-spec-stubs-{today}-{spec_slug}.apply.yaml",
    source_skill="ingest-spec",
    generated_at=today,
    actions=actions,
)
```

Body:

```markdown
---
type: index
schema_version: 1
proposal_kind: ingest-spec-stubs
spec_note: "[[<spec-name>]]"
generated_at: <ISO-8601-UTC>
---

## Summary

- fuzzy matches awaiting confirmation: <n>
- new stubs awaiting approval: <n>

## Fuzzy Matches (user: confirm or reject each)

### <Term>

- top candidates (difflib ratio):
  - `<candidate-1>` (<score>)
  - `<candidate-2>` (<score>)
  - `<candidate-3>` (<score>)
- actions:
  - accept as `[[<chosen>]]` — run `add-to-knowledge-bank` or hand-edit: promote `**<Term>**` to `[[<chosen>]]` in the spec and in the promote-references list below; append `<Term>` to `aliases:` on `<chosen>` if it's a genuine alias.
  - treat as new stub — move to the New Stubs section manually; re-run ingest-spec is NOT needed.
  - remove from spec — hand-edit the spec to drop the term.
- where `**<Term>**` appears today (bold plain text; promote after decision):
  - `Specs/<spec-name>.md` (always)

## New Stubs (user: approve, refine type, or reject)

Tick the checkbox below to approve a stub — `kb-apply` will invoke the `create_note` op with the proposed template + name fields. Unchecked stubs are ignored.

- [ ] `create-stub-<slug>` — <Term> (proposed type: `<type>`, path: `<path>`)

### <Term>

- sidecar action id: `create-stub-<slug>`
- proposed type: `<heuristic-type>` — see reasoning below
- proposed path: `<directory>/<filename>.md`
- proposed template: `00-Meta/Templates/<type>.md`
- heuristic reasoning: <one line on why this type was chosen>
- where `**<Term>**` appears today (bold plain text; promote after stub creation):
  - `Specs/<spec-name>.md`
- next step: tick the box above and run `kb-apply`, OR run `add-to-knowledge-bank` for richer stub content.

## Promote-References Checklist

After you approve any term above and create/link the corresponding note, the bold plain-text references in the spec need to be promoted to `[[wikilinks]]`. The easiest path:

1. Edit `Specs/<spec-name>.md`; grep for `**<Term>**`.
2. Wrap the term in `[[...]]` (remove the bolding — wikilinks render their own emphasis).
3. Add the target's `documented_in: "[[<spec-name>]]"` if it's not already there.
4. Run `python3 00-Meta/Scripts/integrity.py --fix-auto` to repair the inverse automatically.
```

**Type heuristic** (for the New Stubs "proposed type" field) — deterministic, not an LLM judgement:

| shape of term                                      | proposed type |
| -------------------------------------------------- | ------------- |
| `<name>Workflow`, `*Workflow`                      | workflow      |
| `<db>.<table>` (exactly one dot)                   | table         |
| `<namespace>.<topic-with-hyphens>`                 | topic         |
| ends in `_daily`, `_rollup`, `_etl`, `_hourly`     | dag           |
| PascalCase, single word, ends in `UI` or `Console` | tool          |
| PascalCase, single word                            | platform      |
| kebab-case, ends in `-service`                     | service       |
| otherwise, lowercase multi-word                    | concept       |

This is intentionally conservative — the user refines in the proposal.

### 7. Run integrity check before committing

```bash
python3 00-Meta/Scripts/integrity.py --fix-auto
```

Expected: zero remaining issues. If ANY remain, abort before committing — a dangling link in the new spec means the extraction misclassified a term, and that's a bug to investigate, not a commit to make. `git reset --hard HEAD` to back out the stubs proposal and the spec note.

### 8. Emit counters

```json
{"skill":"ingest-spec","spec":"<name>","exact":<n>,"fuzzy":<n>,"new":<n>,"edges_added":<n>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Regenerate manifest.** `python3 00-Meta/Scripts/manifest.py`.
2. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-ingest-spec.md`.
3. **Commit.**
   ```bash
   git add -A
   git commit -m "ingest-spec: <name> (<exact> linked, <fuzzy+new> pending)" \
              -m "Body lists every touched note. Fuzzy/new terms await review in proposals/."
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- **MCP fetch fails** (Confluence page doesn't exist, auth error, 5xx): ask the user to fall back to paste mode; do NOT attempt to synthesize content.
- **Exact-match ambiguity** (`name` resolves to >1 note): stop — integrity has been broken upstream. Tell the user, release the lock, do not write anything.
- **Integrity check fails after writing the spec**: `git reset --hard HEAD`, release the lock, report which check failed. Never commit a broken vault.

## Non-goals

- **Never auto-creates a stub note.** Every unmatched term flows through `proposals/ingest-spec-stubs-*.md` for explicit approval.
- **Never writes a dangling `[[wikilink]]`.** Unmatched terms are `**bold plain text**` only.
- **Never edits notes beyond the new spec and inverse `documented_in` additions on exact-matched targets.** If the spec references a prose fact that contradicts an existing note, that's a job for `add-to-knowledge-bank`, not this skill.
