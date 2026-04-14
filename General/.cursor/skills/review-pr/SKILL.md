---
description: Review the current PR. Workspace must already be the repo checked out to the PR branch. No URLs or network calls needed.
globs:
alwaysApply: false
---

# PR Review

When the user asks to review a PR, follow these steps exactly.

**Assumption:** The Cursor workspace is the repo, already checked out to the PR branch. No network calls are made.

## Step 0 — Detect SCM

Print `**Step 0 — Detecting SCM...**` before starting.

Check which SCM is available in the workspace root:

```bash
ls -d .git .sl 2>/dev/null
```

- If `.git` exists, use the **Git** subsections in Steps 1–3.
- If only `.sl` exists (no `.git`), use the **Sapling** subsections in Steps 1–3.
- If both exist, prefer **Git**. Only fall back to Sapling if the Git commands fail.

## Step 1 — Identify the PR context

Print `**Step 1 — Identifying PR context...**` before starting.

### Git

Run these in parallel:

```bash
basename "$(git rev-parse --show-toplevel)"
```

```bash
git rev-parse --abbrev-ref HEAD
```

```bash
git rev-parse --verify origin/master >/dev/null 2>&1 && echo origin/master || echo origin/main
```

### Sapling

Run these in parallel:

```bash
basename "$(sl root)"
```

```bash
sl log -r . -T '{branch}\n'
```

```bash
sl log -r "remote/master" >/dev/null 2>&1 && echo remote/master || echo remote/main
```

Store the results as `<REPO>`, `<BRANCH>`, and `<BASE>` for use in subsequent steps and the review header.

## Step 2 — Collect changed files

Print `**Step 2 — Collecting changed files...**` before starting.

Substitute the `<BASE>` placeholder in the commands below with the literal value from Step 1 (e.g. `origin/main` or `remote/main`). Do the same for `<FILE>` in Step 3.

### Git

```bash
git diff --stat <BASE>...HEAD && echo "---" && git diff --name-only <BASE>...HEAD
```

### Sapling

```bash
sl diff -r "<BASE>.." --stat && echo "---" && sl diff -r "<BASE>.." --stat | sed '$d' | awk '{print $1}'
```

Parse the file list from the output below the `---` separator. Use the `--stat` portion above it to orient yourself on the shape of the change.

## Step 3 — Review files

Print the status line with the file count before starting (e.g. `**Step 3 — Reviewing 5 files...**`).

Process files **one at a time**. For each file, do all of the following before moving to the next file:

1. **Diff** — get the per-file diff:
   - Git: `git diff <BASE>...HEAD -- <FILE>`
   - Sapling: `sl diff -r "<BASE>.." <FILE>`
2. **Read** — if the diff raises a question you cannot answer from context alone (e.g. whether a caller already null-checks, what interface a class implements, how a modified function is used), read the full file.
3. **Review** — analyze the diff and write your findings for this file immediately, using the severity levels and guidelines in Step 5. Do **not** defer the review to a later step.

Do NOT batch all diffs first — review each file's diff before fetching the next. As you review each file, you naturally accumulate context about the full PR — use this to spot cross-file issues as they emerge.

## Step 4 — Cross-file review

Print `**Step 4 — Cross-file review...**` before starting.

After reviewing all files individually, do one final pass to check for cross-file issues. You already have full context from Step 3 — look specifically for:

- **Broken contracts** — a function signature, interface, or type changed in one file without corresponding updates in callers/implementors in other changed files.
- **Missing propagation** — a new field, renamed constant, or changed enum value not reflected in mappers, serializers, or consumers in other changed files.
- **Inconsistent behavior** — divergent error handling, logging, or validation for the same operation across multiple changed files.
- **Incomplete refactors** — partial renames, moved code with stale references left behind in other changed files.

If needed, re-fetch specific per-file diffs from Step 3 to confirm a suspicion. Do **not** report speculative cross-file issues without verifying against the actual diff.

## Step 5 — Final review output

Print `**Step 5 — Final review output...**` before starting.

Compile all per-file findings (Step 3) and cross-file findings (Step 4) into a single numbered review. If there are no findings at all, say: `✅ No issues found. LGTM.`

### Output format

**File references must use the full relative path from the repo root** (exactly as shown in the diff output), wrapped in backticks — e.g. `` `src/Services/MyService.cs:42` ``, not just `` `MyService.cs:42` ``. This makes them clickable in the IDE and renders as inline code on GitHub.

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

<concise description of defect>

Corrected:
```cs
// small snippet showing the fixed code
```

### 2. 🚨 Issue — `path/to/other.cs:88`

<concise description of the problem>

### 3. ❓ Question — `path/to/file.cs:10`

<the question, directly>

### 4. 💡 Suggestion — `path/to/other.cs:55`

<what to change and why, briefly>

### 5. 🚨 Issue — cross-file: `src/Services/file.cs` + `src/Services/other.cs`

<description of the cross-file issue, referencing both files>
````

### Severity levels

Follows [Conventional Comments](https://conventionalcomments.org/). Items above the divider **block merge**; items below do not.

#### Blocking

- 🐛 **Bug** — correctness defect, crash, data loss, security vulnerability, race condition, undefined behavior. Does **not** include typos, minor textual errors, or broken markdown formatting — those are 🔍 Nitpick. Each Bug finding **must** include a small corrected code snippet.
- 🚨 **Issue** — broken contract, missing validation, unhandled error path, data integrity problem, regression risk, performance cliff. Includes likely bugs carried over from pre-existing code if the diff re-introduces or preserves them in new/refactored code.

#### Non-blocking

- 💡 **Suggestion** — meaningful improvement: simpler approach, better abstraction, reduced duplication, clearer naming. Only use when you have a **concrete recommendation**. If the right approach is ambiguous, use ❓ Question instead.
- ❓ **Question** — request for clarification on intent, design choice, or edge-case behavior. **Prefer this over 💡 Suggestion when you can't confidently say which direction is better** — ask the author rather than prescribing.
- 🔍 **Nitpick** — typos, duplicate words, broken markdown formatting (malformed tables, non-clickable links), lint/convention violations (missing EOF newline, wrong import order per project config).

### Review guidelines

- **GitHub-ready markdown.** Wrap all function names, class names, variable names, and inline code references in backticks (e.g. `GetUserAsync()`, `userId`). For file paths, use the full relative path as described in the output format section. The output should be directly pasteable into a GitHub PR comment.
- **Be concise and direct.** State the problem or question plainly in 1–3 sentences. Do not over-explain or pad with hedging language.
- Focus on the **diff only** — do not comment on unchanged code.
- For C# code: flag missing `null` checks on nullable refs, improper `async`/`await` usage, unnecessary allocations in hot paths, missing `using` statements, and violated naming conventions.
- For proto/config changes: flag missing or mismatched HTTP transcoding annotations, breaking field number changes, and incorrect option usage.
- Do not state the obvious (e.g. "this line adds X") — only flag issues or improvements.
- **No praise.** Do not include 🌟 Praise findings.
- Group findings by file when there are many.
