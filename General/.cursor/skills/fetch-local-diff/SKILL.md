---
description: Fetch the diff for uncommitted working changes vs HEAD — repo/branch context, stat, file list, per-file diffs. Use when the user wants to inspect or work with working changes without running a full review.
globs:
alwaysApply: false
---

# Fetch Local Diff

Retrieve the diff for uncommitted working changes vs HEAD.

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

Store the results as `<REPO>` and `<BRANCH>` for use in subsequent steps and the output header.

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

## Step 3 — Filter test files

Print `**Step 3 — Filtering test files...**` before starting.

Identify test files from the Step 2 file list — any file that is clearly a test by name (e.g. `*.test.*`, `*_test.*`, `*.spec.*`, `Test*.cs`, `*Tests.cs`) or by directory (e.g. `tests/`, `__tests__/`, `spec/`).

- If **all** changed files are test files, keep the full list (don't drop anything — otherwise there is nothing left to diff).
- Otherwise, drop the test files from the list used in Step 4.

The `--stat` output from Step 2 is preserved as-is in the final output so the reader can still see that tests changed; only the per-file diffs for tests are omitted.

## Step 4 — Fetch per-file diffs

Print the status line with the file count before starting (e.g. `**Step 4 — Fetching diffs for N files...**`).

For each file from the filtered list in Step 3, fetch its per-file diff:

- Git: `git diff -- <FILE>`
- Sapling: `sl diff <FILE>`

Collect the diffs keyed by file path for use in Step 5.

## Step 5 — Present results

Print `**Step 5 — Local diff...**` before starting.

Format output as GitHub-ready markdown:

````
## Local Diff — <REPO> (<BRANCH>, uncommitted)

### Stat

```
<stat output from Step 2>
```

### Files

- `path/to/file1.cs`
- `path/to/file2.cs`

_Test files omitted from per-file diffs (see stat above): `path/to/foo.test.ts`, `path/to/bar_test.py`._

### Diffs

**`path/to/file1.cs`**

```diff
<per-file diff from Step 4>
```

**`path/to/file2.cs`**

```diff
<per-file diff from Step 4>
```
````

The `Files` section lists only the filtered (non-test) files. Include the `_Test files omitted..._` line only if tests were actually dropped in Step 3; skip it otherwise.
