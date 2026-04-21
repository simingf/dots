---
description: Review the current PR. Workspace must already be the repo checked out to the PR branch. No URLs or network calls needed.
globs:
alwaysApply: false
---

# PR Review

When the user asks to review a PR, follow these steps exactly.

## Step 1 — Fetch PR diff

Print `**Step 1 — Fetching PR diff...**`

Read and execute the [fetch-pr-diff](../fetch-pr-diff/SKILL.md) skill in full. This produces `<REPO>`, `<BRANCH>`, `<BASE>`, and per-file diffs for each changed file. The fetch skill drops test files from the per-file diffs (unless the only changed files are tests, in which case they are kept).

## Step 2 — Review files

Print the status line with the file count before starting (e.g. `**Step 2 — Reviewing N files...**`).

Process files **one at a time**. For each file, do all of the following before moving to the next file:

1. **Read** — if the diff raises a question you cannot answer from context alone, read the full file.
2. **Review** — analyze the diff and write your findings for this file immediately, using the severity levels and guidelines in Step 4. Do **not** defer the review to a later step.

## Step 3 — Cross-file review

Print `**Step 3 — Cross-file review...**` before starting.

Do one final pass looking for cross-file issues:

- Broken contracts or missing propagation across changed files.
- Inconsistent error handling, logging, or validation across changed files.
- Incomplete refactors with stale references left behind.

Do **not** report speculative cross-file issues — verify against the actual diff first.

## Step 4 — Final review output

Print `**Step 4 — Final review output...**` before starting.

Compile all per-file findings (Step 2) and cross-file findings (Step 3) into a single numbered review. If there are no findings at all, say: `✅ No issues found. LGTM.`

### Output format

File references must use the **full relative path** from the repo root in backticks (e.g. `` `src/Services/MyService.cs:42` ``).

Return a markdown table followed by per-finding detail blocks:

````
## Review — <REPO> (<BRANCH>)

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

#### Non-blocking

- 💡 **Suggestion** — meaningful improvement: simpler approach, better abstraction, reduced duplication, clearer naming. Only use when you have a **concrete recommendation**; if ambiguous, use ❓ Question instead. Start with "would it be better if…". Each Suggestion finding **must** include a small code snippet showing the suggested change.
- ❓ **Question** — request for clarification on intent, design choice, or edge-case behavior. **Prefer this over 💡 Suggestion when you can't confidently say which direction is better.** Start questions with "curious why…".
- 🔍 **Nitpick** — typos, duplicate words, broken markdown formatting, lint/convention violations. Start with "nit: …".

### Review guidelines

- **GitHub-ready markdown.** Wrap code references in backticks. Output should be directly pasteable into a GitHub PR comment.
- **Be concise and direct.** 1–3 sentences per finding. No hedging.
- Focus on the **diff only** — do not comment on unchanged code or state the obvious.
- **No praise.** Group findings by file when there are many.
