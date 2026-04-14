---
name: roblox-trino
description: Query Roblox's data lake using Trino (PrestoSQL) and Hive tables. Use when writing ad-hoc SQL queries over dw_pii, dw_nonpii, ingest_proto, or other data lake schemas, checking table schemas, partitioning data, investigating data freshness, or understanding which tables contain specific Roblox event data.
---

# Trino / Hive — Roblox Data Lake SQL

Trino (formerly PrestoSQL) is Roblox's interactive SQL engine over the data lake stored in S3/Hive. It is used for ad-hoc analytics, data exploration, and reading pipeline outputs.

> **ETL via Trino is not supported.** Use Spark (via Powerhouse) for all ETL workloads. Trino is read-only/ad-hoc.

## Key Links

- **Trino endpoint:** `prod-adhoc-trino-aws.dic.rbx.com:443`
- **Superset:** `superset.prod.dic.rbx.com` (Trino-backed query UI)
- **DBeaver setup:** connect with username=AD credentials, catalog=`hive`
- **Confluence:** [Trino](https://roblox.atlassian.net/wiki/spaces/data/pages/2306802281) | [Datalake Schemas & Access Controls](https://roblox.atlassian.net/wiki/spaces/data/pages/3829465321) | [Platform Events Data Guide](https://roblox.atlassian.net/wiki/spaces/~63ad3f9c159df2c252e79a8d/pages/4030464214)

## Key Schemas

| Schema         | Contents                                     | Notes                      |
| -------------- | -------------------------------------------- | -------------------------- |
| `dw_pii`       | Curated DW tables with PII (user IDs, etc.)  | Requires PII access        |
| `dw_nonpii`    | Curated DW tables without PII                | Default for most analytics |
| `ingest_proto` | Raw protobuf event data from ESI/EventStream | ~1 day lag                 |
| `ingest_eaas`  | CDC data from EaaS entity groups             |                            |
| `olap`         | OLAP aggregation tables                      | Fast, pre-aggregated       |

## Basic Query Patterns

```sql
-- Always check max partition before querying — most tables partition by date
SELECT MAX(ds) FROM dw_nonpii.game_play_sessions;

-- Query with partition filter (REQUIRED for large tables)
SELECT
    universe_id,
    COUNT(*) AS session_count,
    SUM(duration_seconds) AS total_duration
FROM dw_nonpii.game_play_sessions
WHERE ds = '2025-01-15'
GROUP BY universe_id
ORDER BY session_count DESC
LIMIT 100;

-- Check table schema
DESCRIBE dw_nonpii.game_play_sessions;

-- List tables in a schema
SHOW TABLES IN dw_nonpii LIKE '%universe%';
```

## Querying Proto Event Data

```sql
-- Find events from ingest_proto (raw event stream tables)
-- Table names follow the proto FQN pattern
SELECT
    universe_id,
    score,
    ds
FROM ingest_proto.eventstream_esp_myteam_myevent
WHERE ds >= '2025-01-01'
  AND ds <= '2025-01-07'
LIMIT 1000;
```

## Useful IP Scanner / Content Understanding Tables

```sql
-- Universe engagement features (written by Powerhouse DAGs)
SELECT * FROM dw_nonpii.universe_engagement_features
WHERE ds = '2025-01-15' AND universe_id = 7110742552;

-- In-experience string features (written by ip-scanner's Airflow DAG)
SELECT * FROM dw_nonpii.in_experience_string_features_daily
WHERE ds = '2025-01-15'
LIMIT 10;
```

## Connecting via DBeaver

```
Driver:       Trino (PrestoSQL)
Host:         prod-adhoc-trino-aws.dic.rbx.com
Port:         443
Catalog:      hive
Auth:         Username + Password (AD credentials)
SSL:          enabled
```

## Common Pitfalls

- **Missing `WHERE ds = ...`** on partitioned tables → full table scan, very slow and expensive
- **CTE syntax in Superset visual mode** is unsupported — switch to "SQL Lab" or "Code" mode
- **Data lag:** `ingest_*` tables typically have **1-day delay**; always check `MAX(ds)` first
- **PII access:** `dw_pii` requires explicit approval; request via IT/data access request
- **No writes:** Trino is read-only; use Powerhouse/Spark for ETL writes
