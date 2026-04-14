---
description: Review uncommitted working changes vs HEAD. Workspace must already be the repo. No URLs or network calls needed.
globs:
alwaysApply: false
---

# Review Working Changes

When the user asks to review their working changes, follow these steps exactly.

## Step 0 — Detect SCM

Print `**Step 0 — Detecting SCM...**` before starting.

Check which SCM is available in the workspace root:

```bash
ls -d .git .sl 2>/dev/null
```

- If `.git` exists, use **Git** subsections. If only `.sl` exists, use **Sapling**.
- If both exist, prefer **Git**.

## Step 1 — Identify the context

Print `**Step 1 — Identifying context...**` before starting.

### Git

Run these in parallel:

```bash
basename "$(git rev-parse --show-toplevel)"
```

```bash
git rev-parse --abbrev-ref HEAD
```

### Sapling

Run these in parallel:

```bash
basename "$(sl root)"
```

```bash
sl log -r . -T '{branch}\n'
```

Store the results as `<REPO>` and `<BRANCH>` for use in subsequent steps and the review header.

## Step 2 — Collect changed files

Print `**Step 2 — Collecting changed files...**` before starting.

### Git

```bash
git diff --stat && echo "---" && git diff --name-only
```

### Sapling

```bash
sl diff --stat && echo "---" && sl diff --stat | sed '$d' | awk '{print $1}'
```

Parse the file list from the output below the `---` separator. Use the `--stat` portion above it to orient yourself on the shape of the change.

**Exclude test files** — drop any file that is clearly a test (by name or directory) before proceeding to Step 3.

## Step 3 — Review files

Print the status line with the file count (excluding tests) before starting (e.g. `**Step 3 — Reviewing N files...**`).

Process files **one at a time**. For each file, do all of the following before moving to the next file:

1. **Diff** — get the per-file diff:
   - Git: `git diff -- <FILE>`
   - Sapling: `sl diff <FILE>`
2. **Read** — if the diff raises a question you cannot answer from context alone, read the full file.
3. **Review** — analyze the diff and write your findings for this file immediately, using the severity levels and guidelines in Step 5. Do **not** defer the review to a later step.

Do NOT batch execute all diffs — review each file's diff first before fetching the next.

## Step 4 — Cross-file review

Print `**Step 4 — Cross-file review...**` before starting.

Do one final pass looking for cross-file issues:

- Broken contracts or missing propagation across changed files.
- Inconsistent error handling, logging, or validation across changed files.
- Incomplete refactors with stale references left behind.

Do **not** report speculative cross-file issues — verify against the actual diff first.

## Step 5 — Final review output

Print `**Step 5 — Final review output...**` before starting.

Compile all per-file findings (Step 3) and cross-file findings (Step 4) into a single numbered review. If there are no findings at all, say: `✅ No issues found. LGTM.`

### Output format

File references must use the **full relative path** from the repo root in backticks (e.g. `` `src/Services/MyService.cs:42` ``).

Return a markdown table followed by per-finding detail blocks:

````
## Review — <REPO> (<BRANCH>, uncommitted)

| # | File | Line | Severity | Summary |
|---|------|------|----------|---------|
| 1 | `path/to/file.cs` | 42 | 🐛 Bug | Null ref on nullable param not handled |
| 2 | `path/to/other.cs` | 88 | 🚨 Issue | Duplicate field value — likely copy-paste bug |
| 3 | `path/to/file.cs` | 10 | ❓ Question | Is this fallback intentional? |
| 4 | `path/to/other.cs` | 55 | 💡 Suggestion | Consider frozen `dataclass` to enforce immutability |
| 5 | (cross-file) | — | 🚨 Issue | Signature changed in `src/Services/file.cs` but caller in `src/Services/other.cs` not updated |

---

### 1. 🐛 Bug — `path/to/file.cs:42`

<concise description of bug>

```cs
// small snippet showing the fixed code
```

### 2. 🚨 Issue — `path/to/other.cs:88`

<concise description of the problem>

### 3. ❓ Question — `path/to/file.cs:10`

curious why <the question, directly>?

### 4. 💡 Suggestion — `path/to/other.cs:55`

would it be better if <what to change and why, briefly>?

```cs
// small snippet showing the suggested change
```

### 5. 🚨 Issue — cross-file: `src/Services/file.cs` + `src/Services/other.cs`

<description of the cross-file issue, referencing both files>
````

### Severity levels

Follows [Conventional Comments](https://conventionalcomments.org/).

#### Blocking

- 🐛 **Bug** — correctness defect, crash, data loss, security vulnerability, race condition, undefined behavior. Does **not** include typos, minor textual errors, or broken markdown formatting — those are 🔍 Nitpick. Each Bug finding **must** include a small corrected code snippet.
- 🚨 **Issue** — broken contract, missing validation, unhandled error path, data integrity problem, regression risk, performance cliff. Includes likely bugs carried over from pre-existing code if the diff re-introduces or preserves them in new/refactored code.

**Language-specific flags:**

- C#: missing `null` checks on nullable refs, improper `async`/`await` usage, unnecessary allocations in hot paths, missing `using` statements, violated naming conventions.
- Proto/config: missing or mismatched HTTP transcoding annotations, breaking field number changes, incorrect option usage.

#### Non-blocking

- 💡 **Suggestion** — meaningful improvement: simpler approach, better abstraction, reduced duplication, clearer naming. Only use when you have a **concrete recommendation**; if ambiguous, use ❓ Question instead. Start with "would it be better if…". Each Suggestion finding **must** include a small code snippet showing the suggested change.
- ❓ **Question** — request for clarification on intent, design choice, or edge-case behavior. **Prefer this over 💡 Suggestion when you can't confidently say which direction is better.** Start questions with "curious why…".
- 🔍 **Nitpick** — typos, duplicate words, broken markdown formatting, lint/convention violations. Start with "nit: …".

### Review guidelines

- **GitHub-ready markdown.** Wrap code references in backticks. Output should be directly pasteable into a GitHub PR comment.
- **Be concise and direct.** 1–3 sentences per finding. No hedging.
- Focus on the **diff only** — do not comment on unchanged code or state the obvious.
- **No praise.** Group findings by file when there are many.
