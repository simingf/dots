---
name: roblox-rss
description: Use Roblox Similarity Search (RSS) for vector embedding indexing and ANN similarity queries. Use when integrating semantic search, similarity matching, vector indexing, or when working with embeddings, Milvus, RSS corpuses, or content similarity features at Roblox.
---

# Roblox Similarity Search (RSS)

RSS abstracts ANN (Approximate Nearest Neighbor) search over Milvus clusters hosting billions of embeddings. It is the standard platform for semantic search and content similarity at Roblox.

## Key Links

- **Repo:** `github.rbx.com/Roblox/sdp-similarity-search`
- **Docs:** [Pages site](https://pages.github.rbx.com/Roblox/sdp-similarity-search/) (VPN required)
- **Confluence:** [RSS Overview](https://roblox.atlassian.net/wiki/spaces/SDP/pages/1578371310) | [CU Runbook](https://roblox.atlassian.net/wiki/spaces/CU/pages/2691236079)
- **Slack:** `#sdp-rss-users`

## Core Concepts

| Term         | Meaning                                             |
| ------------ | --------------------------------------------------- |
| **Corpus**   | A named collection of embeddings (one per use-case) |
| **AddItems** | Ingest embeddings into a corpus                     |
| **Search**   | ANN query — returns top-K most similar items        |
| **GetItems** | Retrieve metadata without computing similarity      |

## Onboarding a New Corpus

1. Determine embedding model + dimension (e.g., CLIP/SigLIP at 768d)
2. File a request in `#sdp-rss-users` for corpus provisioning
3. Use the RSS Python client to add items and query

```python
from rss_client import RSSClient

client = RSSClient(corpus="your-corpus-name")

# Ingest embeddings (batch preferred)
client.add_items([
    {"id": "item-1", "embedding": [0.1, 0.2, ...], "metadata": {"type": "image"}},
])

# Search
results = client.search(query_embedding=[0.1, 0.2, ...], top_k=10)
```

## SLOs

- Search P99 < **50ms** for ~20M embeddings at 200 QPS (dim ≤ 512)
- GetItems P99 < **20ms** at 200 QPS

## Resource Estimates

- ~0.6 GB RAM per 1M embeddings (dim=512)
- Static cluster overhead: ~256 GB RAM, ~300 GHz CPU
- Scale query nodes by QPS: ~40 GHz + ~6 GB per query node per 100 QPS

## Active Corpuses at Roblox (examples)

- Decal image embeddings (CLIP) — used by Creator Marketplace image search
- In-experience content embeddings — used by IP Scanner deep scan
- Audio embeddings (CLAP) — used by Content Safety audio similarity rejection

## Common Pitfalls

- **Memory retrieval is 4x more expensive** — avoid retrieving embeddings at high QPS if not needed; use `GetItems` for metadata-only lookups
- **Ingestion at >200 QPS** spikes CPU — batch ingestion off-peak or increase indexing nodes
- For production use, request a dedicated Milvus cluster if >100M embeddings or >100 QPS

## Reference

- [Introduction to using RSS for RAG (Comm Safety)](https://roblox.atlassian.net/wiki/spaces/SAFE/pages/4468769056)
- [RSS Service Deployments](https://roblox.atlassian.net/wiki/spaces/SDP/pages/1967392027)
