---
name: roblox-prometheus
description: Instrument Roblox BEDEV2 services with Prometheus metrics and write alert rules. Use when adding custom counters, histograms, or gauges to a C# service, writing PromQL alert expressions, setting up Grafana dashboards, or configuring PagerDuty alerts in the o11y-alerts repo.
---

# Prometheus Metrics at Roblox

Prometheus is the standard observability layer for all BEDEV2 services. Metrics are scraped from service endpoints and visualized in Grafana. Alerts are defined as YAML in `Roblox/o11y-alerts`.

## Key Links

- **Alerts repo:** `github.rbx.com/Roblox/o11y-alerts`
- **Grafana:** `grafana.rbx.com`
- **Confluence:** [1004.0 - Using metrics (BEDEV2)](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531873112) | [BEDEV2 Alerts → PagerDuty](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531875771)

## Adding Custom Metrics to a C# Service

BEDEV2 framework automatically exposes standard service metrics (request rate, latency, error rate). For custom metrics, use Prometheus client libraries:

```csharp
using Prometheus;

// Define metrics as static fields (created once)
private static readonly Counter _scanRequests = Metrics
    .CreateCounter("ip_scanner_scan_requests_total",
        "Total number of scan requests",
        labelNames: new[] { "status" });

private static readonly Histogram _scanDuration = Metrics
    .CreateHistogram("ip_scanner_scan_duration_seconds",
        "Duration of scan operations",
        new HistogramConfiguration
        {
            Buckets = Histogram.ExponentialBuckets(0.01, 2, 10) // 10ms to ~10s
        });

// Instrument your code
public async Task<ScanResult> ScanAsync(ScanRequest request)
{
    using var timer = _scanDuration.NewTimer();
    try
    {
        var result = await DoScanAsync(request);
        _scanRequests.WithLabels("success").Inc();
        return result;
    }
    catch (Exception)
    {
        _scanRequests.WithLabels("error").Inc();
        throw;
    }
}
```

## Metric Types

| Type        | Use For                                              | Example                    |
| ----------- | ---------------------------------------------------- | -------------------------- |
| `Counter`   | Things that only go up (requests, errors)            | `requests_total`           |
| `Histogram` | Latency distributions                                | `request_duration_seconds` |
| `Gauge`     | Values that go up and down (queue depth, cache size) | `active_connections`       |

## Naming Conventions

- Format: `<service>_<noun>_<unit>` — e.g., `ip_scanner_scan_duration_seconds`
- Counters end in `_total`
- Units must be base SI: `_seconds`, `_bytes`, `_requests`

## Writing Alert Rules

Alerts live in `Roblox/o11y-alerts` under your team's directory:

```yaml
# o11y-alerts/content-understanding/ip-scanner-alerts.yml
groups:
  - name: ip-scanner
    rules:
      - alert: IpScannerHighErrorRate
        expr: |
          sum(rate(ip_scanner_scan_requests_total{status="error"}[5m]))
          / sum(rate(ip_scanner_scan_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
          team: content-understanding
        annotations:
          summary: "IP Scanner error rate > 5%"
          runbook: "https://roblox.atlassian.net/wiki/spaces/CU/pages/3603104238"

      - alert: IpScannerHighLatency
        expr: |
          histogram_quantile(0.99,
            rate(ip_scanner_scan_duration_seconds_bucket[5m])
          ) > 2.0
        for: 5m
        labels:
          severity: warning
```

## Routing Alerts to PagerDuty

See [BEDEV2 Alerts Guide](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531875771) — add your service's PagerDuty service key to the alert routing config in `bedev2-production`.

## Common PromQL Patterns

```promql
# P99 latency
histogram_quantile(0.99, rate(my_service_duration_seconds_bucket[5m]))

# Error rate
sum(rate(my_service_requests_total{status="error"}[5m]))
/ sum(rate(my_service_requests_total[5m]))

# Request rate by label
sum by (status) (rate(my_service_requests_total[1m]))
```

## Grafana Managed Dashboards

BEDEV2 auto-generates a "managed" Grafana dashboard per service. Find it at:
`grafana.rbx.com/d/<service-name>-managed`
