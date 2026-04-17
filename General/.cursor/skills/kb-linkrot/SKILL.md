---
description: Check external URLs in the Roblox knowledge-bank vault at /Users/sfeng/roblox-obsidian for rot. Hybrid classifier — Confluence URLs resolved via the Atlassian MCP, public URLs HEAD-checked with a short timeout, internal *.rbx.com URLs syntax-checked only (the agent's shell is not on VPN). Propose-only. Use when the user asks "check the links", "are any links dead", "link rot", "404 external URLs", "verify vault URLs", or runs periodic maintenance.
globs:
alwaysApply: false
---

# kb-linkrot

Check every external URL that appears in vault frontmatter and flag the rotten ones.

Because most Roblox URLs are internal (gated by VPN + corporate SSO) and cannot be reached from the agent's shell, this skill uses a three-way strategy:

| URL class       | Where                                          | How it's checked                           |
| --------------- | ---------------------------------------------- | ------------------------------------------ |
| `confluence`    | host `*.atlassian.net`                         | Atlassian MCP `confluence_get_page` lookup |
| `public_http`   | github.com, docs.google.com, temporal.io, etc. | `urllib.request` HEAD, 5s timeout          |
| `internal_http` | `*.rbx.com`, `*.simulprod.com`                 | syntax-check only; flagged for manual pass |

Never auto-mutates note bodies. When a URL fails, the only thing written is the proposal file.

## Preflight

Skip every step prefixed `[standalone]` when `KB_DRIVEN_BY=kb-weekly`.

1. `[standalone]` **Lock.**
   ```bash
   cd /Users/sfeng/roblox-obsidian
   if [ -f 00-Meta/.lock ]; then echo "vault locked; aborting"; exit 1; fi
   echo "kb-linkrot $(date -u +%FT%TZ)" > 00-Meta/.lock
   ```
2. `[standalone]` **Clean tree.** `git status --porcelain` must be empty. Abort if not.
3. Confirm the Atlassian MCP (`user-mcp-atlassian`) is available — if not, the Confluence class will silently fall through to the same treatment as `internal_http`.

## Work

### 1. Extract + classify URLs

```bash
cd /Users/sfeng/roblox-obsidian
python3 00-Meta/Scripts/linkrot.py --json > /tmp/kb-linkrot.json
```

Output: `{url_count, counts_by_class, urls[]}`. Each `urls[]` entry has `note_path`, `note_type`, `url`, `field`, `class`.

### 2. Check each URL

Process the three classes differently.

#### 2a. `class: "public_http"` — HEAD with urllib

Run inline Python (stdlib only; ThreadPoolExecutor for 8-way parallelism, 5s per-URL timeout, 0 redirects so short-links can't tarpit us):

```bash
python3 <<'PY' > /tmp/kb-linkrot-public.json
import json, urllib.request, urllib.error, ssl
from concurrent.futures import ThreadPoolExecutor, as_completed

with open('/tmp/kb-linkrot.json') as f:
    report = json.load(f)
targets = [u for u in report['urls'] if u['class'] == 'public_http']
ctx = ssl.create_default_context()

def head(u):
    req = urllib.request.Request(u['url'], method='HEAD', headers={'User-Agent': 'kb-linkrot/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=5, context=ctx) as r:
            return {**u, 'status': r.status, 'error': None}
    except urllib.error.HTTPError as e:
        return {**u, 'status': e.code, 'error': f'HTTP {e.code}'}
    except Exception as e:
        return {**u, 'status': None, 'error': f'{type(e).__name__}: {e}'}

results = []
with ThreadPoolExecutor(max_workers=8) as ex:
    futs = [ex.submit(head, u) for u in targets]
    for f in as_completed(futs):
        results.append(f.result())
json.dump({'checked': len(results), 'results': results}, open('/tmp/kb-linkrot-public.json','w'), indent=2)
print(f'public_http checked: {len(results)}')
PY
```

A public URL is "broken" if `error` is set OR `status >= 400`. Redirects are NOT followed, so a 301/302 is not an error — re-HEAD the `Location` header manually if it looks suspicious.

#### 2b. `class: "confluence"` — Atlassian MCP

For each Confluence URL, extract the page ID from the URL path (the integer segment after `/pages/`). Use the Atlassian MCP tool `confluence_get_page` with that ID:

```
CallMcpTool(
  server="user-mcp-atlassian",
  toolName="confluence_get_page",
  arguments={"page_id": "<extracted-id>"}
)
```

A Confluence URL is "broken" if the MCP returns an error (`page not found`, `forbidden`, `deleted`) OR returns no content. Otherwise it is live.

Budget: hit the MCP at most once per unique page ID. Do not re-check pages that appear in multiple notes.

#### 2c. `class: "internal_http"` — syntax-check only

Do NOT issue HTTP requests. These hosts require VPN; a HEAD from the agent's shell fails regardless of rot state and would produce pure false positives. Instead:

- Verify the URL parses (scheme, host, path) — script already did this.
- Flag each one with status `"internal-not-checked"`.
- In the proposal, group them under a separate section so the user can open them by hand when on VPN.

### 3. Emit the sidecar (only if anything is broken)

Pipe the broken public + Confluence records into `linkrot.py --emit-sidecar`:

```bash
python3 <<'PY' > /tmp/kb-linkrot-broken.json
import json
pub = json.load(open('/tmp/kb-linkrot-public.json'))
broken = [r for r in pub['results'] if r.get('error') or (r.get('status') and r['status'] >= 400)]
# Add confluence records the MCP could not fetch — the agent populates
# /tmp/kb-linkrot-confluence-broken.json during step 2b.
import os
if os.path.exists('/tmp/kb-linkrot-confluence-broken.json'):
    broken += json.load(open('/tmp/kb-linkrot-confluence-broken.json'))
json.dump(broken, open('/tmp/kb-linkrot-broken.json','w'))
print(f'linkrot broken: {len(broken)}')
PY

TODAY=$(date -u +%F)
python3 00-Meta/Scripts/linkrot.py \
  --emit-sidecar "00-Meta/Maintenance/proposals/linkrot-${TODAY}.apply.yaml" \
  --broken-from /tmp/kb-linkrot-broken.json \
  > /dev/null
```

Each broken URL becomes a `remove_external_url` action. Internal URLs are NOT put in the sidecar — they go into a separate "manual check required" section of the proposal `.md`.

### 4. Write the proposal markdown (only if anything is broken or internal-uncertain)

Filename: `00-Meta/Maintenance/proposals/linkrot-$(date -u +%F).md`

Body template:

```markdown
---
type: index
schema_version: 1
proposal_kind: linkrot
generated_at: <ISO-8601-UTC>
url_count: <total>
broken_public: <n>
broken_confluence: <n>
internal_not_checked: <n>
---

## Summary

- total URLs scanned: <url_count>
- public broken (status >= 400 or error): <broken_public>
- confluence missing/forbidden: <broken_confluence>
- internal URLs (manual check required): <internal_not_checked>

## Action

Tick a checkbox below to remove that URL from its note's frontmatter (`remove_external_url` op), then run `kb-apply`. To update an URL in place instead of removing it, leave the checkbox unchecked and edit the note directly.

For internal URLs: connect to VPN and hit each URL; if still alive, no action. If dead, edit the note directly and commit — internal URLs are NOT in the sidecar because automated auth-gated checks are unsafe.

## Proposed actions

- [ ] `linkrot-<note-slug>-<host-slug>` — remove `<url>` from `<note_path>:<field>`  (<reason>)

<one bullet per broken public or confluence URL; all default-unchecked>

## Broken public URLs (diagnostics)

<one H3 per URL, sorted by note_path>

### <url>

- sidecar action id: `linkrot-<note-slug>-<host-slug>`
- note: `<note_path>` field: `<field>`
- status: <status> error: <error>

## Broken confluence URLs (diagnostics)

<one H3 per URL>

### <url>

- sidecar action id: `linkrot-<note-slug>-<host-slug>`
- note: `<note_path>` field: `<field>`
- mcp_error: <error returned by confluence_get_page>
- page_id: <extracted>

## Internal URLs (manual check required)

Listed by note so the user can walk them once on VPN.

- `<note_path>` — <url> (<field>)
- ...
```

Only write the proposal when there's at least one broken public URL, one broken Confluence URL, or the user explicitly requested the internal listing (the weekly sweep always includes it; on-demand runs may skip it if `--quiet` is requested by the user).

### 4. Emit counters

```json
{"skill":"kb-linkrot","urls":<total>,"broken_public":<n>,"broken_confluence":<n>,"internal":<n>,"proposals":<0-or-1>}
```

## Finalize

Skip every step in this section when `KB_DRIVEN_BY=kb-weekly`.

1. **Log.** Append counters to `00-Meta/Maintenance/logs/$(date -u +%F)-kb-linkrot.md` with per-URL detail (abridged to 20 entries max).
2. **Update `last-run.yaml`** — `kb-linkrot.last_run_at`, `outcome` (`clean` iff zero broken), `urls_checked`, `urls_broken` (public + confluence, not including internal-not-checked).
3. **Commit (if anything changed — typically `last-run.yaml` and possibly a new proposal).**
   ```bash
   git add -A
   git commit -m "kb-linkrot: <broken> broken, <internal> internal uncertain"
   ```
4. **Release lock.** `rm 00-Meta/.lock`.

## Non-goals

- kb-linkrot never edits a note's `external_links:` or `sources:` automatically. A replaced URL is a content judgement, not a mechanical swap.
- kb-linkrot never follows redirects. A 301/302 is reported as-is; if you want to record the new canonical URL, that's `add-to-knowledge-bank`'s job.
- kb-linkrot never checks internal URLs over the network. If you want live-check for internal, run this skill on your own machine with VPN — the code path is the same, just classify `internal_http` manually as `public_http` before the HEAD phase.
- kb-linkrot never issues GET requests. HEAD-only by policy (some sites disable HEAD; those count as broken until the user verifies by hand).
