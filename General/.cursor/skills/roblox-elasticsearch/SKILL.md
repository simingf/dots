---
name: roblox-elasticsearch
description: Work with Elasticsearch clusters at Roblox for text search and document indexing. Use when querying the es-rights-management index for IP scanner candidate generation, updating an Elasticsearch index mapping/schema, writing a new indexing pipeline to Elasticsearch, debugging search query relevance, or onboarding a new ES cluster.
---

# Elasticsearch at Roblox

Roblox runs multiple dedicated Elasticsearch clusters for different use cases. The one most relevant to IP scanning and content understanding is **`es-rights-management`**, which stores in-experience string features queried during candidate generation.

## Key Links

- **es-rights-management Kibana:** `es-rights-management-kibana-chi1.simulprod.com`
- **Elastic users Slack:** `#elastic-users`
- **CU Runbook:** [Updating es-rights-management mappings/schema](https://roblox.atlassian.net/wiki/spaces/CU/pages/3723886616)

## es-rights-management Index

This index stores per-universe features used by `ip-scanner` for text-based candidate generation:

| Field                                 | Description                                                              |
| ------------------------------------- | ------------------------------------------------------------------------ |
| `universeId`                          | Universe ID                                                              |
| `universeName`                        | Experience name (analyzed for text search)                               |
| `universeDescription`                 | Description text                                                         |
| `inExperienceStringFeatures`          | Nested array of strings seen in-experience (populated by Powerhouse DAG) |
| `universeEngagementFeatures.dau7dAvg` | 7-day average DAU (used for scoring)                                     |
| `universeQualityFeatures.isPublic`    | Whether experience is public                                             |

## Querying with the Dev Console (Kibana)

```json
// Search by IP keyword across name, description, and in-experience strings
POST /multi-index-0/_search
{
  "from": 0,
  "size": 20,
  "_source": ["universeId", "universeName", "universeEngagementFeatures"],
  "query": {
    "bool": {
      "must": [
        { "range": { "universeEngagementFeatures.dau7dAvg": { "gte": 50 } } },
        { "term": { "universeQualityFeatures.isPublic": true } },
        {
          "bool": {
            "should": [
              { "match": { "universeName.shinglesWithStopwords": { "query": "minecraft", "boost": 5 } } },
              { "match_phrase": { "universeDescription.shinglesWithStopwords": { "query": "minecraft", "boost": 3 } } }
            ],
            "minimum_should_match": 1
          }
        }
      ]
    }
  }
}
```

## Updating the Index Mapping (Schema Change Process)

> ⚠️ The `es-rights-management` index has **dynamic mapping disabled** — you must explicitly add new fields before writing them.

```
1. Open PR to update index_mapping.json in the CU repo
2. Get review from #elastic-users / CU team
3. Deploy mapping change to ST3 first
4. Validate documents are written with new fields as expected
5. Test search queries against ST3
6. Deploy to production
```

See: [Runbook: Updating es-rights-management mappings/schema](https://roblox.atlassian.net/wiki/spaces/CU/pages/3723886616)

## Adding a New Field

```json
// PUT /multi-index-0/_mapping
{
  "properties": {
    "myNewFeature": {
      "type": "float"
    }
  }
}
```

Then update your indexing pipeline (Powerhouse DAG) to write the new field. Deploy the mapping change **before** the pipeline change.

## Writing to Elasticsearch from a Powerhouse DAG

```python
# In your Powerhouse pipeline, write to ES via the ES sink
from powerhouse import ElasticsearchSink

pipeline = NamedQuery(
    name="update_universe_features",
    query="SELECT universe_id, my_new_feature FROM ...",
    sinks=[
        ElasticsearchSink(
            cluster="es-rights-management",
            index="multi-index-0",
            id_field="universe_id",
        )
    ]
)
```

## Querying from C# (ip-scanner)

```csharp
// ip-scanner uses the NEST/Elasticsearch.Net client
var searchResponse = await _elasticClient.SearchAsync<UniverseDocument>(s => s
    .Index("multi-index-0")
    .Query(q => q
        .Bool(b => b
            .Must(
                m => m.Range(r => r
                    .Field(f => f.EngagementFeatures.Dau7dAvg)
                    .GreaterThanOrEquals(50)),
                m => m.Match(mt => mt
                    .Field(f => f.UniverseName)
                    .Query(ipKeyword))
            )
        )
    )
    .Size(500));
```

## Common Issues

- **Field not indexed:** Dynamic mapping is disabled — update the mapping before writing new fields
- **Slow queries:** Check for missing `filter` context vs `query` context (filters are cached, faster)
- **Stale data:** In-experience string features are updated daily via Airflow DAG — check DAG run status
- **Cluster health:** Check `es-rights-management-kibana-chi1.simulprod.com/app/monitoring` for cluster health
