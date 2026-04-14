---
name: roblox-superset
description: Create dashboards and run SQL queries in Roblox's Superset data visualization tool. Use when building a new metrics dashboard, writing Trino/Hive SQL in Superset's SQL Lab, setting up data alerts for a pipeline, sharing a chart with a team, debugging a Superset query error, or monitoring IP scanner / deep scan evaluation results.
---

# Superset — Data Visualization & Dashboards

Superset is Roblox's open-source data visualization and dashboarding tool, backed by Trino/Hive. It is the standard tool for pipeline monitoring, experiment analysis, and business metrics charting.

## Key Links

- **URL:** `superset.prod.dic.rbx.com`
- **Slack:** `#data-users`
- **Confluence:** [Using Superset](https://roblox.atlassian.net/wiki/spaces/data/pages/1542752337)

## Querying Data (SQL Lab)

Use **SQL Lab** (top nav → SQL → SQL Lab) for free-form Trino queries.

```sql
-- Always filter by partition date to avoid expensive full scans
SELECT
    ds,
    universe_id,
    score,
    reason
FROM ingest_proto.eventstream_esp_contentunderstanding_deepscanresult
WHERE ds >= '2025-01-01'
  AND ds <= '2025-01-07'
ORDER BY score DESC
LIMIT 500;
```

**Known Superset SQL quirks:**

- CTEs (`WITH ... AS (...)`) **do not work** in the visual query builder — use SQL Lab instead
- `$partitions` pseudo-table: `SELECT MAX(ds) FROM hive.dw_nonpii.my_table$partitions`
- Use single quotes for strings, not double quotes

## Building a Chart

1. SQL Lab → run your query → click **Explore** to build a chart from results
2. Or: **Charts** → **+ Chart** → select dataset → choose visualization type
3. Common chart types: Time Series Line, Bar Chart, Big Number, Table

## Building a Dashboard

1. **Dashboards** → **+ Dashboard**
2. Drag and drop charts onto the canvas
3. Add filters (date range, universe ID) using the **Filters** panel
4. Use **Cross-filter** to let charts filter each other on click

## Setting Up Data Alerts

Superset alerts can notify you when a metric crosses a threshold:

1. **Alerts & Reports** → **+ Alert**
2. Set the SQL condition (e.g., `SELECT COUNT(*) FROM ... WHERE score > 0.9 AND ds = '{{ ds }}'`)
3. Set threshold and schedule (cron)
4. Add Slack channel or email as notification target

Example alert for IP scanning:

```sql
-- Alert if deep scan result count drops below expected threshold
SELECT COUNT(*) FROM ingest_proto.eventstream_esp_contentunderstanding_deepscanresult
WHERE ds = '{{ macros.ds_add(ds, -1) }}'
```

## Useful Dashboards

| Dashboard               | URL Pattern                                                 | Used For                           |
| ----------------------- | ----------------------------------------------------------- | ---------------------------------- |
| IP Scanning Online Eval | `superset.prod.dic.rbx.com/superset/dashboard/ip_scanning/` | Monitor deep scan precision/recall |
| Universe Engagement     | search "universe engagement"                                | DAU, session data by universe      |

## Sharing & Permissions

- Dashboards are shareable via URL — recipients need a Superset account
- For PII data: ensure all viewers have PII access approved before sharing dashboards that query `dw_pii`
- Mark dashboards as "Published" to make them discoverable in the dashboard list

## Common Issues

- **"Not a SELECT" error:** You used CTE syntax in visual mode — switch to SQL Lab
- **Slow query:** Missing partition filter; add `WHERE ds = '...'`
- **Data stale:** Check `MAX(ds)` — `ingest_*` tables have ~1 day lag
- **Chart not updating:** Dashboard cache may be stale; click the refresh icon or adjust cache TTL in chart settings
