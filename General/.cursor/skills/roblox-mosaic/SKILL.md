---
name: roblox-mosaic
description: Deploy and manage BEDEV2 services at Roblox using Mosaic. Use when triggering a production rollout, checking canary analysis results, debugging a failed deployment, editing Nomad specs, updating instance counts, rolling back a service, or navigating to a service's deployment page.
---

# Mosaic — BEDEV2 Service Deployment

Mosaic is Roblox's unified deployment UI for BEDEV2 services. It replaced the old DevOps tab and is the mandatory deployment path for all production rollouts. Every production deploy gets **Automated Canary Analysis (ACA)**.

## Key Links

- **UI:** `mosaic.rbx.com/service/<product>/<service>/deployment`
- **Nomad specs repo:** `github.rbx.com/Roblox/deployment`
- **Slack:** `#mosaic`
- **Confluence:** [FAQ for MDS/BEDEV2 on Mosaic](https://roblox.atlassian.net/wiki/spaces/ENGEFF/pages/1963165695) | [Mosaic Manual & CD Feature Parity](https://roblox.atlassian.net/wiki/spaces/ENGEFF/pages/3529146572)

## Deployment Workflow

```
1. Merge PR to service repo → GitHub Actions builds Docker image
2. Image appears in Mosaic's "Builds" tab
3. Click "Deploy" → Mosaic starts canary rollout via Nomad/MDS
4. ACA runs automatically — monitors error rate, latency vs baseline
5. If ACA passes → rollout continues cell-by-cell
6. If ACA fails → deployment auto-stops; investigate logs
```

## Finding Your Service

```
# URL pattern:
https://mosaic.rbx.com/service/{product}/{service}/deployment

# Examples:
https://mosaic.rbx.com/service/creator-content-search/ip-scanner/deployment
https://mosaic.rbx.com/service/creator-cu/experience-deep-scan-workflow/deployment
```

## Nomad Spec Location

Deployment specs live in `Roblox/deployment`:

```
deployment/
└── nomad/
    └── {product}/
        └── {service}/
            └── production/
                └── {cluster}/
                    └── job.nomad
```

Edit Nomad specs for resource tuning (CPU, memory, instance count) via PRs to `Roblox/deployment`.

## Common Operations

**Scale up (emergency):**
Edit `job.nomad` → increase `count` → open PR to `Roblox/deployment` → deploy via Mosaic.

**Scale to zero (decommission):**
Set `count = 0` in Nomad spec → merge → Mosaic will terminate all allocations.

**Rollback:**
In Mosaic's rollout table, click the previous build → "Deploy" → rolls back to that image.

**Check logs:**
Mosaic links to Kibana/Loki logs directly from the rollout table. Or use the logs URL in each service's runbook.

## Canary Analysis (ACA)

ACA compares the new version to the baseline (old version) on key metrics:

- Error rate delta
- P99 latency delta
- Custom metrics defined in the service

If ACA fails, the rollout stops automatically. Check the ACA report in Mosaic for which metric triggered the failure.

## Build Not Showing Up?

- Verify GitHub Actions "Build Docker image" step completed on the PR
- Ensure the service's Nomad spec is merged into `Roblox/deployment`
- Check `components_k8s.json` (for K8s services) is updated
- See: [Why are my service builds not showing up in Mosaic?](https://roblox.atlassian.net/wiki/spaces/ENGEFF/pages/2685109331)
