---
description: Fetch GitHub PR review data for the current branch — review verdicts, inline code comments, and general discussion. Use when the user wants to see review feedback, comments, or approval status for their current PR.
globs:
alwaysApply: false
---

# Fetch PR Reviews

Retrieve review data for the PR associated with the current branch.

## Step 0 — Detect SCM

Print `**Step 0 — Detecting SCM...**` before starting.

Check which SCM is available in the workspace root:

```bash
ls -d .git .sl 2>/dev/null
```

- If `.git` exists, use **Git** subsections. If only `.sl` exists, use **Sapling**.
- If both exist, prefer **Git**.

## Step 1 — Identify the PR

Print `**Step 1 — Identifying PR...**` before starting.

### Git

**1.** Parse `<HOST>`, `<OWNER>`, `<REPO>` from the remote URL:

```bash
git remote get-url origin
```

**2.** Look up the open PR for the current branch — store `<PR>`, `<TITLE>`, `<HEAD_REF>`, `<BASE_REF>`:

```bash
gh pr view --json number,title,headRefName,baseRefName,url \
  --jq '{number, title, head_ref: .headRefName, base_ref: .baseRefName, url}'
```

If `gh pr view` fails with "no pull requests found", tell the user there is no open PR for the current branch.

### Sapling

**1.** Parse `<HOST>`, `<OWNER>`, `<REPO>` from the remote URL:

```bash
sl paths default
```

**2.** Find `<PR>` from the smartlog — look for the `@` line (current commit) and extract the number after `#`:

```bash
sl ssl
```

Example output:

```
@  08e3802aa6  Yesterday at 18:11  sfeng  #541 Unreviewed ✓
```

Here `<PR>` = `541`. If no `#<number>` appears on the `@` line, tell the user there is no open PR for the current commit.

**3.** Fetch PR details — store `<TITLE>`, `<HEAD_REF>`, `<BASE_REF>`:

```bash
gh api --hostname <HOST> repos/<OWNER>/<REPO>/pulls/<PR> \
  --jq '{title, head_ref: .head.ref, base_ref: .base.ref}'
```

## Step 2 — Fetch review data

Print `**Step 2 — Fetching review data...**` before starting.

Run all three calls in parallel:

### Top-level reviews (approve / request changes / comment)

```bash
gh api --hostname <HOST> repos/<OWNER>/<REPO>/pulls/<PR>/reviews \
  --jq '.[] | {id, user: .user.login, state, body}'
```

### Inline review comments (code suggestions live here)

```bash
gh api --hostname <HOST> repos/<OWNER>/<REPO>/pulls/<PR>/comments
```

### General PR comments (filter out bots)

```bash
gh api --hostname <HOST> repos/<OWNER>/<REPO>/issues/<PR>/comments \
  --jq '.[] | select(.user.type != "Bot") | {id, user: .user.login, body}'
```

## Step 3 — Handle errors

Print `**Step 3 — Checking for errors...**` before starting.

If **any** `gh api` call fails (HTTP 421, 401, auth errors, etc.):

1. Run `gh auth status` and show the output to the user.
2. Prompt the user to re-authenticate: `gh auth login --hostname <HOST>`
3. Retry the failed calls after the user confirms auth is fixed.

## Step 4 — Present results

Print `**Step 4 — PR review summary...**` before starting.

Format output as GitHub-ready markdown:

````
## PR Reviews — <OWNER>/<REPO>#<PR>

**<TITLE>**
`<BASE_REF>` ← `<HEAD_REF>`

### Reviews

| Reviewer | State | Summary |
|----------|-------|---------|
| @user1 | ✅ APPROVED | Looks good |
| @user2 | 🔄 CHANGES_REQUESTED | See inline comments |

### Inline Comments

Group by file, then by thread (`in_reply_to_id`). Show the diff hunk for context on the first comment in each thread.

**`path/to/file.cs:42`**
```diff
<diff_hunk from the first comment in the thread>
````

**@reviewer1**: Comment body or suggestion

> **@reviewer2** (reply): Follow-up comment

### Discussion

**@user**: <first line or truncated body>

```

Omit any section that has no data (e.g. skip "Discussion" if there are no general comments).
ye
```
