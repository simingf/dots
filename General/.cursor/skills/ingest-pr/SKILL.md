---
description: Ingest a merged GitHub PR into the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Dual entry points — `gh pr view <url>` (works for github.com out of the box; github.rbx.com depends on the user's local gh GHE config) or pasted diff + PR body (universal manual path). Maps touched files to vault notes via the manifest, updates `last_modified_pr` + bounded `recent_prs`, proposes (never auto-creates) a `type: bug` stub when the PR body matches `fixes #NNN` + bug keywords. Never writes dangling wikilinks. Use when the user asks to ingest a PR, extract knowledge from a merged PR, or record a recent change against the vault.
globs:
alwaysApply: false
---

# ingest-pr

Mirror `ingest-spec`'s integrity discipline for merged pull requests: pull the diff + PR body, map each touched file to an existing vault note, update tracking frontmatter on that note, and — if the PR looks like it fixed a bug — propose a `type: bug` stub rather than creating one silently.

**Core integrity invariant**: this skill never writes a dangling `[[wikilink]]`. Repos, services, workflows that don't have a vault note are surfaced in the proposal file as bold plain text; the user creates the note (via `add-to-knowledge-bank` or hand edits) before any link is wired.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly` (not typical — this is a write-time skill).

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "ingest-pr $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Read `00-Meta/Schema.md` (the fields this skill touches: `last_modified_pr`, `recent_prs`, and the `bug` type) and `00-Meta/Conventions.md` §PR tracking.
4. Determine the input:
   - **URL input** — user provides `https://github.com/<org>/<repo>/pull/<n>` OR `https://github.rbx.com/<org>/<repo>/pull/<n>`. Try `gh pr view <url> --json number,title,body,url,mergedAt,author,files`. If `gh` rejects GHE (common unless `gh auth login --hostname github.rbx.com` has been run), fall through to paste mode.
   - **Paste input** — user pastes the PR body plus the output of `git show --stat <merge-sha>` or a raw unified diff. Ask for `title`, `url`, `merged_at`, `author`, and the `files[]` list if the paste is bare.

## Work

### 1. Normalize input to a PR record

Regardless of source, end up with:

- `pr_number` (int)
- `pr_url` (string — canonical `https://github.<host>/org/repo/pull/N`)
- `pr_title` (string)
- `pr_body` (markdown text)
- `merged_at` (YYYY-MM-DD; UTC)
- `author` (string)
- `repo_full_name` (`<org>/<repo>`, lowercase)
- `touched_files` (list of relative paths from the diff)

### 2. Map the repo to a vault note

Use the manifest:

```bash
MANIFEST=/Users/sfeng/roblox-obsidian/00-Meta/vault-index.json
```

Match order:

1. **Exact** — `jq --arg u "$pr_url" '.notes[] | select(.type=="repo" and (.github_url // "" | startswith($u_prefix)))' $MANIFEST` where `$u_prefix` is the repo root URL (e.g. `https://github.rbx.com/Roblox/off-platform-ads-service`). The manifest stores repo notes with `github_url`; ingest-pr relies on this.
2. **By name** — fall back to `jq --arg n "Roblox.$repo_short" ...` where `$repo_short` is the segment after the org.
3. **No match** — the repo has no vault note yet. Record this in the stubs proposal as a "new repo stub"; do NOT create the repo note automatically. The skill continues to the next step so workflow/service/etc notes can still be updated, but `implemented_in_repo` edges stay disconnected.

### 3. Map each touched file to an impacted note

Strategy (most specific → most general):

1. **Path conventions** — `src/<PascalCase>.cs` hints at a BEDEV2 service in `<repo_short>`; `dags/<snake.case>_daily.py` hints at a DAG; `workflows/<Name>.cs` hints at a workflow. Build a per-repo hint table inline.
2. **Name match** — for each candidate name derived from step 1, look up the manifest for a note whose `name` (or `aliases[]`) matches. Record a hit as an `impacted_note`.
3. **Fallback** — if no per-file hit but a `repo` note exists, consider the repo note itself impacted.

The output of this step is `impacted_notes: list[{path, type, name}]` (deduplicated) and `unmapped_files: list[str]` (for the stubs proposal).

### 4. Update each impacted note

For every entry in `impacted_notes`, edit its frontmatter:

- Set `last_modified_pr: "<pr_url>"` (overwrite any previous value).
- Append to `recent_prs: []` — FIFO max length 5. Keep the older entries; pop the oldest if the list would exceed 5. Each entry is the PR URL (string, not an object, for ease of `grep`).
- If either field is missing from the note's frontmatter, add it as a new top-level key just before `last_verified:`.

Do NOT set `last_verified:` — a PR being merged does not mean a human re-read the note. Freshness stays in `kb-freshness` territory.

Do NOT mutate any structural field (`calls_services`, `writes_tables`, etc.) — inference from diffs is unreliable, and a wrong edit corrupts the bidirectional graph. If the PR changed the topology, the user records that via `add-to-knowledge-bank` after merging.

### 5. Detect bug-fix pattern

Treat the PR as a bug-fix candidate if ANY of:

- `pr_body` matches `/(?i)\b(fixes|closes|resolves)\s*#\d+/`
- `pr_title` or `pr_body` contains at least one bug keyword: `null ref`, `NullReferenceException`, `timeout`, `OOM`, `deadlock`, `race condition`, `panic`, `stack overflow`, `segfault`, `off-by-one`, `regress`, `hotfix`
- An attached paste includes a stack trace recognizable to `symptom_sig.py` (run it on any triple-backtick block and check if it produces a non-empty `key`).

If the pattern matches, proceed to step 6. Otherwise skip to step 7.

### 6. Propose a bug stub (never auto-create)

Filename:

```
00-Meta/Maintenance/proposals/ingest-pr-stubs-$(date -u +%F)-<pr-slug>.md
```

where `<pr-slug>` is derived from `pr_title` (lowercased, spaces → hyphens, punctuation stripped, max 40 chars).

Body template:

```markdown
---
type: index
schema_version: 1
proposal_kind: ingest-pr-stubs
pr_url: "<pr_url>"
pr_title: "<pr_title>"
merged_at: <YYYY-MM-DD>
generated_at: <ISO-8601-UTC>
---

## Summary

- PR: <pr_url>
- title: <pr_title>
- trigger(s): <list of which detection signals fired — "fixes #", "bug keywords", "stack trace present">
- proposed bug name: `YYYY-MM-DD-<short-slug>` (date = merged_at)

## Action

1. Review the PR (link above).
2. If this is genuinely a reusable bug report (future agents could match future failures to it), create `Bugs/YYYY-MM-DD-<slug>.md` from `00-Meta/Templates/bug.md`. Copy the symptom_signature block below verbatim.
3. Fill in `root_cause_summary` and `fix_summary` from the PR description.
4. Add `[[<slug>]]` to the `related_bugs:` field of every note in "Impacted notes" below (`add-to-knowledge-bank` can automate this).

If this is NOT a reusable bug (e.g., a one-off typo fix, a refactor, a feature), delete this proposal file.

## Proposed frontmatter (hand edit as needed)

```yaml
type: bug
name: YYYY-MM-DD-<slug>
aliases: []
status: fixed
schema_version: 1
severity: <user-edits — medium default>
affected_service: "<user-edits — pick from impacted notes>"
also_affects: []
occurred_at: <user-edits — may differ from merged_at>
fixed_at: <merged_at>
symptom_signature: |
  <symptom_sig.build() key, one line per field — or "" if no stack trace in the PR>
root_cause_summary: "<one-sentence summary from the PR body>"
fix_summary: "<one-sentence summary of the fix>"
fix_prs: ["<pr_url>"]
prevention: []
related_projects: []
tags: [type/bug, domain/<user-edits>, platform/<user-edits>]
last_verified: <merged_at>
```

## Impacted notes (bold plain text if no vault note yet)

<one bullet per impacted_notes entry>

- `<path>` — type=<type>, name=<name>  (will gain `related_bugs: ["[[<new-bug-slug>]]"]` after you approve)

## Unmapped files (potential new notes)

<one bullet per unmapped_files entry>

- `<file>` — no manifest match; **<PascalCase or heuristic name>** could become a new note. Review with `add-to-knowledge-bank`.
```

Only write the proposal if the pattern fired in step 5. If the user later rejects, the recommended cleanup is `rm proposals/ingest-pr-stubs-YYYY-MM-DD-<slug>.md`.

### 7. Run integrity check before committing

```bash
python3 00-Meta/Scripts/integrity.py --fix-auto
```

Expected: zero remaining issues. If ANY remain, abort — a new `recent_prs` entry shouldn't cause dangling links, so an error means the mapping misidentified an impacted note. `git reset --hard HEAD` and investigate.

### 8. Emit counters

```json
{"skill":"ingest-pr","pr":"<pr_url>","impacted":<n>,"unmapped_files":<m>,"bug_stub_proposed":<bool>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Regenerate manifest.** `python3 00-Meta/Scripts/manifest.py`.
2. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-ingest-pr.md`.
3. **Commit.**
   ```bash
   git add -A
   git commit -m "ingest-pr: <pr-slug> (<n> notes updated)" \
              -m "PR: <pr_url>. Bug stub: <yes|no>. Unmapped files: <m>."
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Failure handling

- **`gh pr view` fails on GHE** — expected when `gh auth login --hostname github.rbx.com` has not been run. Ask the user to paste the PR body + diff manually; do not attempt to scrape the URL.
- **Repo has no vault note** — record in the unmapped-files proposal; continue updating non-repo impacted notes if any.
- **Zero impacted notes and no bug trigger** — do not write anything. Release the lock, report "nothing to ingest — this PR didn't touch any vault-tracked resource."

## Non-goals

- **Never auto-creates a bug note.** The user approves the stub in the proposal file and creates the note with `add-to-knowledge-bank` (or the bug template directly).
- **Never writes dangling `[[wikilinks]]`.** Unmapped repos/files/entities are bold plain text in the proposal.
- **Never edits structural fields** (`calls_services`, `writes_tables`, etc.). A PR diff is too noisy a signal for topology inference.
- **Never follows cross-repo PR references** (e.g. a PR in Repo A that "depends on roblox/foo#123"). Each PR is ingested atomically; chasing cross-repo references is manual.
- **Never bumps `last_verified:`** — PR merge is a code event, not a human re-verification.
