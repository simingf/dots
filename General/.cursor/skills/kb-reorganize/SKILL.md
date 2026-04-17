---
description: Detect promotion candidates in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian — notes that have grown past the leaf-size thresholds and should be split into a hub-plus-subfolder per ADR-0005. Propose-only; never auto-promotes a note (a bad promotion corrupts inbound link topology). Use when the user asks "what notes are too big", "which hubs need splitting", "reorganize the vault", "promotion candidates", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-reorganize

Flag notes that exceed their type's leaf-shape budget (body length, H2 count beyond template, outbound link count, or any `*_overflow_to` field set) as candidates for promotion per `[[0005-promotion-protocol-hub-outside]]`. The user approves each promotion manually; this skill never mutates a note.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly`.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-reorganize $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Decisions/0005-promotion-protocol-hub-outside.md` (the authoritative promotion protocol) and `00-Meta/AGENTS.md` §8 (summary).

## Work

### 1. Run the promotion-candidate detector + emit sidecar

```bash
cd /Users/sfeng/roblox-obsidian
TODAY=$(date -u +%F)
python3 00-Meta/Scripts/reorganize.py --json \
  --emit-sidecar "00-Meta/Maintenance/proposals/reorganize-${TODAY}.apply.yaml" \
  > /tmp/kb-reorganize.json
```

Each candidate becomes a `promote_to_hub` action in the sidecar. The sidecar op creates the sibling subfolder and stubs a `## Children` block in the hub; manual subnote carve-up still happens after `kb-apply`.

The script output has:

- `thresholds` — the active `MAX_BODY_LINES`, `H2_FLOOR`, `H2_BUFFER`, `MAX_OUTBOUND_STRUCTURAL_LINKS`, and the per-type template H2 baselines it computed.
- `candidate_count`, `already_promoted_skipped`, `candidates[]`.

Each `candidate` entry has `path`, `name`, `type`, `reasons[]`, plus the raw stats (`body_lines`, `h2_count`, `outbound_structural_links`, `overflow_fields`).

### 2. Write the proposal (only if `candidate_count > 0`)

Filename: `00-Meta/Maintenance/proposals/reorganize-$(date -u +%F).md`

Body template:

```markdown
---
type: index
schema_version: 1
proposal_kind: reorganize
generated_at: <ISO-8601-UTC>
candidate_count: <n>
---

## Summary

- promotion candidates: <n>
- already-promoted notes (suppressed): <m>
- thresholds: body_lines > <X>, h2 > template + <buffer> (floor <Y>), outbound_links > <Z>

## Action

Tick a checkbox below to approve that hub's promotion, then run `kb-apply` on this proposal. `kb-apply` invokes the `promote_to_hub` op, which:

1. Keeps the hub note at its current path (inbound links still resolve by basename).
2. Creates the sibling folder with the same stem (e.g. `Platforms/BEDEV2/`).
3. Adds a managed `## Children` section to the hub (if missing) as a placeholder.

You still manually carve subnotes after the op runs — the op provides the structural container, not the content split.

## Proposed actions

- [ ] `promote-<slug>` — <type>: <name>  ({reasons summary})

## Candidates

<one H3 per candidate, sorted by body_lines desc>

### <type>: <name>

- sidecar action id: `promote-<slug>`
- path: `<candidate.path>`
- body_lines: <n>
- h2_count: <n> (template baseline for type=<type>: <baseline>)
- outbound_structural_links: <n>
- overflow_fields: <list or "(none)">
- reasons:
  <one bullet per entry in candidate.reasons[]>

Suggested subnote carve-up (agent reviews the hub's H2 sections and proposes groupings — NOT auto-generated, the agent must actually read the hub):

- `<hub>-<kebab-slug>.md` — covers H2 "<H2 title>" and H2 "<H2 title>"
- …
```

The "suggested subnote carve-up" is the one section that requires the agent to actually open each candidate note and read its H2 structure. The script can't do this — the groupings are a judgement call. Leave the list empty only if the reasons are purely `outbound_links` (in which case the remedy is `<field>_overflow_to: "[[Bases/<base>]]"`, not a subnote split).

### 3. Emit counters

```json
{"skill":"kb-reorganize","candidates":<n>,"suppressed":<m>,"proposals":<0-or-1>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-reorganize.md`.
2. **Update `last-run.yaml`** — `kb-reorganize.last_run_at`, `outcome` (`clean` if 0 candidates else `proposals_created`), `promotion_proposals` to the candidate count.
3. **Commit (if anything changed — typically `last-run.yaml` and possibly a new proposal).**
   ```bash
   git add -A
   git commit -m "kb-reorganize: <n> candidate(s)"
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Non-goals

- kb-reorganize never promotes, renames, or moves notes. Every promotion is human-driven because link topology is the hard part.
- kb-reorganize never touches body content. The "suggested subnote carve-up" lives in the proposal file, not in any note body.
- kb-reorganize never compares across types (that's a routing question for `kb-dedupe`-adjacent tooling in Phase 4).
