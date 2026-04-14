---
name: roblox-frost
description: Use Frost, Roblox's ML feature store built on Feast, for storing and retrieving ML and search signals. Use when defining feature views, materializing features from Powerhouse pipelines, reading features from a C# service, debugging feature serving latency, or onboarding a new feature to the Frost feature store.
---

# Frost — Roblox Feature Store

Frost is Roblox's online ML/search feature store, built on [Feast](https://feast.dev/). It stores and retrieves low-latency signals for ML inference and search ranking. Frost replaces SignalPlatform and Tecton.

## Key Links

- **Repo:** `github.rbx.com/Roblox/frost`
- **Docs:** [GitHub Pages](https://pages.github.rbx.com/Roblox/frost/index.html) (VPN required)
- **Confluence:** [Frost Feature Store](https://roblox.atlassian.net/wiki/spaces/SDP/pages/1978368082) | [Frost Overview](https://roblox.atlassian.net/wiki/spaces/SDP/pages/1978040443)
- **Slack:** `#frost-users`
- **Grafana:** [EaaS Group Dashboard](https://grafana.rbx.com/d/entities-group/entities-group) — filter by `frost-feature-store-*`

## Architecture

```
Powerhouse DAG (daily/hourly)
    ↓ computes features from raw data
Frost materialization-consumer
    ↓ writes to
EaaS wide-column store (frost-feature-store-2, frost-feature-store-sequence-*)
    ↓ read by
frost feature-serving service
    ↓ queried by
Your BD2 service (at online inference time)
```

## Key Concepts

| Term                | Meaning                                                    |
| ------------------- | ---------------------------------------------------------- |
| **Feature View**    | A named set of features for a given entity type            |
| **Entity**          | The key for feature lookup (e.g., `universeId`, `userId`)  |
| **Materialization** | The batch job that computes + writes features to the store |
| **Feature Serving** | The real-time API that retrieves features by entity key    |

## Reading Features from C# (BEDEV2)

```csharp
// Inject the Frost client in Startup.cs
services.AddFrostClient(options =>
{
    options.FeatureStoreName = "frost-feature-store-2";
});

// Fetch features at inference/serving time
public class MyService
{
    private readonly IFrostClient _frost;

    public MyService(IFrostClient frost) => _frost = frost;

    public async Task<UniverseFeatures> GetFeaturesAsync(long universeId)
    {
        var features = await _frost.GetFeaturesAsync(
            featureView: "universe-engagement-features",
            entityKey: universeId.ToString());
        return features;
    }
}
```

## SLO

- Feature serving P99 < **500ms** per entity group
- Errors < 5% per entity group (alert fires above this)

## Adding a New Feature

1. Define feature schema in `frost` repo (feature view YAML)
2. Write the Powerhouse pipeline that computes the feature and writes to Frost
3. Run materialization backfill to populate historical data
4. Add the feature to the feature-serving config
5. Test with `frost-cli` locally before production

## Debugging

```bash
# Use frost-cli to inspect features for a given entity key
frost-cli get --feature-store frost-feature-store-2 \
              --feature-view universe-engagement-features \
              --entity-key 12345678
```

## Common Issues

- **Stale features:** Check Powerhouse DAG run status — materialization runs on a schedule
- **High latency:** Check `feature-serving` Grafana dashboard; EaaS wide-column may need scaling
- **Missing entity:** Feature may not have been materialized yet — check backfill status
- Alert on: `feature_serving_latency_ms_summary{quantile="0.99"} > 500` and error rate > 5%
