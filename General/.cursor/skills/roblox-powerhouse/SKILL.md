---
name: roblox-powerhouse
description: Write, test, and deploy Powerhouse data pipelines at Roblox. Use when creating or modifying Airflow DAGs, building ETL batch pipelines with Powerhouse DSL (NamedQuery, AccumulatorTable), backfilling pipelines, migrating vanilla Airflow pipelines, or debugging Airflow DAG failures in the creator-content-search or other Roblox data contexts.
---

# Powerhouse / Airflow

Powerhouse is Roblox's internal pipeline framework that compiles Python DSL into Airflow DAGs running on Kubernetes. It handles partitioning, retries, compliance, and lineage automatically.

## Key Links

- **Pipelines repo:** `github.rbx.com/Roblox/powerhouse-pipelines` (all team DAGs)
- **DSL/framework repo:** `github.rbx.com/Roblox/powerhouse-dsl`
- **Creator team DAGs:** `github.rbx.com/Roblox/data-pipelines-creator`
- **Confluence:** [[Data 201] - Powerhouse](https://roblox.atlassian.net/wiki/spaces/data/pages/2173993588) | [Your First Pipeline](https://roblox.atlassian.net/wiki/spaces/DP/pages/3759049749)
- **Docs site:** `pages.github.rbx.com/Roblox/powerhouse-dsl/` (VPN required)

## Pipeline Types

| Type               | Use Case                                |
| ------------------ | --------------------------------------- |
| `NamedQuery`       | SQL transformation (SELECT → table)     |
| `AccumulatorTable` | Incrementally accumulate data over time |

## Writing a Pipeline

Pipelines live in `powerhouse-pipelines/k8s/<pillar>/<team>/` or in the `data-pipelines-creator` repo for creator team.

```python
from powerhouse import NamedQuery

# Simple daily SQL pipeline
pipeline = NamedQuery(
    name="my_daily_feature_table",
    tags=["my-team"],
    query="""
        SELECT
            universe_id,
            AVG(dau) AS dau_7d_avg,
            COUNT(*) AS session_count
        FROM roblox.games.sessions
        WHERE date = '{{ ds }}'
        GROUP BY universe_id
    """,
    destination_table="my_team.my_daily_feature_table",
    schedule="0 6 * * *",  # 6 AM UTC daily
)
```

```python
from powerhouse import AccumulatorTable

# Incrementally accumulate data
pipeline = AccumulatorTable(
    name="my_accumulator",
    query="""
        SELECT user_id, SUM(robux_spent) AS total_spent
        FROM roblox.economy.transactions
        WHERE date = '{{ ds }}'
        GROUP BY user_id
    """,
    accumulation_key="user_id",
    destination_table="my_team.my_accumulator",
)
```

## Testing a Pipeline

**Option 1 — Via PR (preferred, more comprehensive):**

1. Push branch to `powerhouse-pipelines`
2. Open a draft PR → GitHub Actions runs "Build Metadata (Dev)"
3. DAG appears in Airflow UI suffixed with your PR number
4. Verify in Airflow UI: click **View in Airflow**

**Option 2 — Powerhouse test command:**

```bash
# From inside the devcontainer (open repo in VSCode → Reopen in Container)
powerhouse test --pipeline my_daily_feature_table --date 2025-01-01
```

## Deploying Changes

1. Merge PR to `master` → pipeline auto-deploys to production Airflow
2. Verify DAG appears in Airflow UI (pillar-specific URL — see [team mapping doc](https://roblox.atlassian.net/wiki/spaces/data/pages/2592374874))

## Backfilling

See [[Data 201 i] - Backfilling a Powerhouse Pipeline](https://roblox.atlassian.net/wiki/spaces/data/pages/2176648953) for per-type examples.

```python
# Trigger a backfill via the Powerhouse backfill pipeline pattern
BackfillPipeline(
    source_pipeline=my_daily_feature_table,
    start_date="2024-01-01",
    end_date="2024-12-31",
)
```

## Migrating Vanilla Airflow → Powerhouse

Replace manual `SparkSubmitOperator` + table DDL with `NamedQuery`:

```python
# Before (vanilla Airflow)
create_table = BigQueryOperator(sql="CREATE TABLE IF NOT EXISTS ...", ...)
run_query = SparkSubmitOperator(sql="INSERT INTO ... SELECT ...", ...)

# After (Powerhouse)
pipeline = NamedQuery(name="my_table", query="SELECT ...", destination_table="...")
```

See [migration guide](https://roblox.atlassian.net/wiki/spaces/data/pages/2653520211).

## Common Issues

- **DAG not showing up:** Check GitHub Actions "Build Metadata (Dev)" step completed successfully
- **Partition errors:** Powerhouse handles partitioning automatically — verify source tables are partitioned by `date`
- **Column lineage missing:** Ensure you're using Powerhouse primitives, not raw `PythonOperator`
