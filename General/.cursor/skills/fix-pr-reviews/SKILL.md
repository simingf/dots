---
description: Fix PR review comments by fetching feedback, letting the user choose which to address, and dispatching parallel subagents to implement fixes. Use when the user wants to fix, address, or resolve PR review comments, reviewer feedback, or code change requests.
globs:
alwaysApply: false
---

# Fix PR Reviews

Fetch PR review comments, let the user select which to fix, dispatch subagents to implement each fix, and report results.

## Step 1 — Fetch PR reviews

Print `**Step 1 — Fetching PR reviews...**`

Read and execute the [fetch-pr-reviews](../fetch-pr-reviews/SKILL.md) skill in full. This produces `<HOST>`, `<OWNER>`, `<REPO>`, `<PR>`, and three data sets:

- Top-level reviews (approve / request changes / comment)
- Inline review comments (full JSON — includes `path`, `line`, `original_line`, `diff_hunk`, `body`, `in_reply_to_id`, `user.login`, `id`)
- General PR comments

Retain the raw inline-comments JSON for Step 2. You will also need `<HOST>`, `<OWNER>`, `<REPO>`, `<PR>` later.

## Step 2 — Extract actionable comments

Print `**Step 2 — Extracting actionable comments...**`

From the inline review comments, build a list of **actionable items** — comments that request a code change.

### 2a. Build threads

Group inline comments by thread: comments sharing the same `in_reply_to_id` (or root comments with no `in_reply_to_id`) form a thread. Keep threads ordered by comment creation time.

### 2b. Filter to actionable threads

A thread is **actionable** if any comment in it:

- Contains a ` ```suggestion ` block, OR
- Requests a code change (fix, rename, refactor, add, remove, move, extract, etc.)

A thread is **not actionable** if it:

- Is only a question with no directive ("curious why…", "is this intentional?")
- Is only an acknowledgement, praise, or resolved discussion
- Is from a bot (`user.type == "Bot"`)
- Has `position: null` with no suggestion (outdated, line no longer exists)

When ambiguous, **include** the thread — the user will deselect it if unwanted.

### 2c. Extract structured records

For each actionable thread, extract:

| Field        | Source                                                             |
| ------------ | ------------------------------------------------------------------ |
| `id`         | root comment `id`                                                  |
| `file`       | `path` field                                                       |
| `line`       | `line` (prefer over `original_line`; fall back to `original_line`) |
| `reviewer`   | `user.login` of the root comment                                   |
| `body`       | full body of root comment                                          |
| `diff_hunk`  | `diff_hunk` from root comment                                      |
| `suggestion` | code inside ` ```suggestion ` block if present (strip the fences)  |
| `replies`    | array of `{user, body}` for each reply in the thread               |

Also scan **general PR comments** (issue comments) for actionable requests. These won't have `file`/`line` — set `file` to `(general)` and `line` to `—`.

If zero actionable comments are found, tell the user and stop.

## Step 3 — Group by file

Print `**Step 3 — Grouping <COUNT> actionable comments by file...**` (with actual count).

Group actionable records by `file`. Comments on the same file **must** go to a single subagent to avoid conflicting edits.

## Step 4 — Prompt user

Print `**Step 4 — Select comments to fix...**`

Use the `AskQuestion` tool with `allow_multiple: true`. Present **one question per file group**. Each option shows:

```
@<reviewer> L<line>: <first 80 chars of body>
```

If there is only one file group, use a single question. If there are many groups, present them all in one `AskQuestion` call (one question per file group).

If the user selects nothing, tell them no fixes were requested and stop.

## Step 5 — Dispatch subagents

Print `**Step 5 — Fixing N comments across M files...**` (with actual counts).

For each file group that has at least one selected comment, launch a `generalPurpose` subagent via the `Task` tool. **Launch all file-group subagents in parallel** (single message, multiple `Task` tool calls) since they touch different files.

Each subagent prompt must include:

1. The repository root path (current working directory).
2. The file path and every selected comment for that file — include `body`, `diff_hunk`, `suggestion`, and `replies` for full context.
3. These instructions:

````
You are fixing PR review comments on a single file.

For each comment:
1. Read the file.
2. Locate the code referenced by the diff hunk and line number.
3. If a ```suggestion``` block is provided, apply that exact replacement.
   Otherwise, implement the change the reviewer requested.
4. After all changes to this file, run ReadLints on the file and fix any
   linter errors you introduced.

When done, return a JSON array (one entry per comment) with this schema:
[
  {
    "id": <comment_id>,
    "file": "<file_path>",
    "line": <line_number>,
    "reviewer": "<username>",
    "status": "success" | "failed",
    "summary": "<1-sentence description of what you changed>",
    "notes": "<optional detail on failure or caveats>"
  }
]

Return ONLY this JSON — no other text.
````

For general (non-file) comments, include them in a separate subagent whose prompt explains there is no specific file and it should determine the relevant files from context.

## Step 6 — Compile results

Print `**Step 6 — Results...**`

Collect the JSON arrays returned by each subagent. Parse them and present a single merged table:

```
## Fix Results — <OWNER>/<REPO>#<PR>

| # | File | Line | Reviewer | Comment | Status | Notes |
|---|------|------|----------|---------|--------|-------|
| 1 | `path/file.cs` | 42 | @user1 | Fix null check | Success | Added null guard on `param` |
| 2 | `path/other.cs` | 88 | @user2 | Rename variable | Failed | Could not locate referenced code |
```

Below the table, if any fixes failed, add a **Failures** section with the full comment body and agent notes so the user can address them manually.

If all fixes succeeded, end with: `All selected review comments have been addressed.`
