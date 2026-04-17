---
description: Match a pasted error/stack trace against existing `type: bug` notes in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian. Uses symptom_signature normalization + scoring to surface prior bugs whose root cause and fix may apply. Read-only — never mutates the vault. Use when the user pastes an error, stack trace, or exception and asks "have we hit this before?", "is this a known bug?", "any fixes for this error?", or similar.
globs:
alwaysApply: false
---

# kb-find-bug

Answer "have we seen this error before?" from the vault.

The vault is a system of record for bugs (`type: bug` under `Bugs/`) that carry a `symptom_signature:` block scalar — the normalized class + message + leading stack frames of the failure. This skill runs the same normalization against the user's pasted error and surfaces the top matches with their `fix_summary`, `prevention`, and a pointer to the note for deep-read.

This skill never writes. It is not part of `kb-weekly`. It runs on demand only.

## Preflight

1. Confirm the vault root: `test -d /Users/sfeng/roblox-obsidian/00-Meta || { echo "not a vault root"; exit 1; }`
2. Confirm Python 3 is available: `python3 --version`.
3. No lock, no dirty-tree check, no git state change — this is a read-only skill.

## Work

### 1. Collect the error text

- If the user pasted an error or stack in the message, use it verbatim.
- If they typed only a short phrase, ask once: "paste the full error or stack trace; one-liners match poorly". Then wait.

### 2. Score against every `type: bug` note

```bash
cd /Users/sfeng/roblox-obsidian
cat <<'ERR' | python3 00-Meta/Scripts/vault_query.py bug-match --top 3
<PASTE THE FULL ERROR HERE, VERBATIM>
ERR
```

The script normalizes via `00-Meta/Scripts/symptom_sig.py` (same codifier used at write time in `add-to-knowledge-bank`), then scores each bug note on:

- `class_match` (boolean) — 40% weight
- `msg_jaccard` (0..1) — 40% weight
- `frame_overlap` (0..1) — 20% weight

### 3. Present the top matches to the user

For each match in the JSON (`matches[]`), read the note body to pull the fields that the frontmatter already exposes (`root_cause_summary`, `fix_summary`, `prevention`), and emit this exact layout:

```
Match N  score=<score>  <note name>
  occurred_at: <date>   status: <status>
  root cause: <root_cause_summary — single line from frontmatter>
  fix:        <fix_summary — single line from frontmatter>
  prevention:
    - <each prevention list entry on its own line>
  path: <Bugs/...md>     (open for full context)
```

If `matches[]` is empty, say:

> No existing bug note matches this signature. Consider capturing it via `add-to-knowledge-bank` once the fix is in.

### 4. Offer the follow-up

End with a single hand-off line:

> To record a new bug for this failure, read `~/.cursor/skills/add-to-knowledge-bank/SKILL.md` and follow the bug-capture path (ADR-0009).

## Finalize

This skill has no Finalize steps. It does not acquire the lock, does not regenerate the manifest, does not log to `Maintenance/`, and does not commit. If `KB_DRIVEN_BY=kb-weekly` is set (it should never be — this skill is not part of the weekly sweep), refuse and exit; this skill is on-demand only.

## Non-goals

- Never creates a new bug note. That is `add-to-knowledge-bank`'s job.
- Never edits a bug note's `fix_summary`, `prevention`, or any other field. If a match is partial, point the user at `add-to-knowledge-bank` instead.
- Never silently "improves" the pasted error (no re-wording, no trimming). The normalization happens inside `symptom_sig.py`; the raw paste is the source of truth.
