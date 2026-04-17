---
description: Roblox knowledge-bank router. Dispatches any vault-related request — reads (lookup, dashboard, bug match), writes (learnings, spec ingest, PR ingest), or maintenance (integrity, freshness, dedupe, reorganize, linkrot, archive, reindex, weekly sweep) — to the correct sub-skill. Use when the user mentions the vault, obsidian, the knowledge store, the knowledge bank, "add to the kb", "weekly upkeep", "check the vault", "what bug matches this", "vault status", Roblox internal knowledge they want recorded or looked up, or anything referring to /Users/sfeng/roblox-obsidian.
globs:
alwaysApply: false
---

# knowledge-bank (router)

This skill does not mutate the vault. It matches user intent to the correct worker skill and tells the agent which SKILL.md to read next.

## Vault location

`/Users/sfeng/roblox-obsidian`

Every worker skill below operates against this path. If the workspace is not this directory, `cd` there before following the worker's instructions.

## Dispatch tables

Match the user's latest message against the intents in the first column. The tables are split by intent kind — scan the three in order: **Read** first (cheapest, no locks), then **Write**, then **Maintenance**. Within each table, the top-most matching row wins. Once matched, read and follow the linked `SKILL.md`.

### Read (no vault mutation, no lock, no commit)

| Intent keywords / phrases                                                                                                                         | Worker skill                                    |
| ------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| "have we seen this error", "known bug", "match this stack trace", "find bug", user pastes an exception / panic / stack and asks about prior fixes | `~/.cursor/skills/kb-find-bug/SKILL.md`         |
| "vault status", "how healthy is the vault", "what's pending review", "dashboard", "when was the vault last maintained"                            | `~/.cursor/skills/kb-status/SKILL.md`           |
| any other read-shaped question: "who owns X", "which DAG writes Y", "what team is on call for Z"                                                  | _no skill — use AGENTS.md §4 navigation ladder_ |

### Write (mutates the vault, acquires lock, emits commit)

| Intent keywords / phrases                                                                                                            | Worker skill                                      |
| ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| "distill this convo", "add to the kb", "record what we learned", "save this", "write up learnings", end-of-session knowledge capture | `~/.cursor/skills/add-to-knowledge-bank/SKILL.md` |
| "ingest spec", "parse this Confluence page / GDoc into the vault", "seed from design doc"                                            | `~/.cursor/skills/ingest-spec/SKILL.md`           |
| "ingest PR", "extract knowledge from this merged PR", "record this PR against the vault"                                             | `~/.cursor/skills/ingest-pr/SKILL.md`             |
| "apply this proposal", "execute the sidecar", "run the .apply.yaml", "apply the latest dedupe/freshness/archive proposal"            | `~/.cursor/skills/kb-apply/SKILL.md`              |
| "verify stale notes", "bump last_verified", "re-verify", interactive per-note freshness curation                                     | `~/.cursor/skills/kb-verify/SKILL.md`             |

### Maintenance (propose-only unless noted; each runs under `kb-weekly` in one sweep)

| Intent keywords / phrases                                                                                   | Worker skill                                       |
| ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| "weekly upkeep", "run the maintenance sweep", "run all the kb checks", "Monday cleanup"                     | `~/.cursor/skills/kb-weekly/SKILL.md` _(umbrella)_ |
| "check the vault", "audit", "verify bidirectional links", "repair dangling links", "integrity"              | `~/.cursor/skills/kb-integrity/SKILL.md`           |
| "what's stale", "freshness", "last_verified"                                                                | `~/.cursor/skills/kb-freshness/SKILL.md`           |
| "find duplicates", "dedupe the vault"                                                                       | `~/.cursor/skills/kb-dedupe/SKILL.md`              |
| "reorganize", "promote this hub", "split a big note", "promotion candidates"                                | `~/.cursor/skills/kb-reorganize/SKILL.md`          |
| "check links", "dead links", "404 external URLs", "link rot"                                                | `~/.cursor/skills/kb-linkrot/SKILL.md`             |
| "archive completed projects", "clean up Projects/Completed" _(auto-applies when `archive-config.yaml :: auto_apply: true`)_ | `~/.cursor/skills/kb-archive/SKILL.md`             |
| "regenerate indexes", "rebuild the index files", "refresh _Index.md" _(auto-apply within managed markers)\_ | `~/.cursor/skills/kb-reindex/SKILL.md`             |

## Look-up vs. mutation

If the user's request is a **read**, route to the Read table above (or fall back to the `AGENTS.md` §4 navigation ladder for ad-hoc questions). Read-shaped queries that match common patterns (ownership, producers/consumers, neighbors, bug match, stale) can go through the shared `vault_query.py` CLI — AGENTS.md §4 rung 2.5 documents this.

If the user's request is a **write or maintenance** action, dispatch to the matching skill and follow its Preflight → Work → Finalize contract.

## Safety clauses

- This router never mutates the vault. All mutations happen in a dispatched worker skill.
- If no row matches, ask one clarifying question of the form: "Is this a read (answer from the vault), a write (add to the vault), or maintenance (audit/cleanup)?"
- Read skills (`kb-find-bug`, `kb-status`) do not acquire the lock and are safe to run any time. Every other skill respects `00-Meta/.lock`.

## Phase awareness

All Phase 1–4 skills are built and wired. The current skill family is 15 entries (router + 5 write-time + 7 maintenance + 2 read):

- router: `knowledge-bank`
- read: `kb-find-bug`, `kb-status`
- write (content authoring): `add-to-knowledge-bank`, `ingest-spec`, `ingest-pr`
- write (proposal execution): `kb-apply` (executes sidecars via `00-Meta/Scripts/apply.py`), `kb-verify` (interactive per-note freshness bumping; feeds `kb-apply`)
- maintenance (propose-via-sidecar): `kb-integrity`, `kb-freshness`, `kb-dedupe`, `kb-reorganize`, `kb-linkrot`
- maintenance (auto-apply when configured): `kb-archive` (behind `archive-config.yaml :: auto_apply: true`), `kb-reindex` (marker-bounded)
- umbrella: `kb-weekly` (runs the 7 maintenance skills in one sweep)

Phase 4 closed the write loop: every maintenance skill emits a paired `.apply.yaml` sidecar, and `kb-apply` is the single executor that runs those sidecars transactionally with integrity-gated rollback.
