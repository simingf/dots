---
name: roblox-qaas
description: Produce and consume Kafka messages using QaaS (Queuing as a Service) at Roblox. Use when setting up a Kafka producer or consumer in a C# or Go service, creating a new QaaS topic, handling consumer lag, configuring DLQs, debugging message processing issues, or replacing SQS with QaaS.
---

# QaaS — Queuing as a Service (Managed Kafka)

QaaS is Roblox's managed Kafka service. It wraps Kafka clusters with Roblox-specific auth, DLQ support, cross-region replication, and credential management via Vault/Secrets Broker.

## Key Links

- **Client lib (Go):** `github.rbx.com/Roblox/qaas-kafka-go`
- **Client lib (.NET):** `Roblox.BEDEV2.Kafka` NuGet package
- **Slack:** `#qaas-users`
- **Grafana:** [QaaS Kafka Topics Dashboard](https://grafana.rbx.com/d/f28c7a91-ab63-4a3b-82ce-c927dda1af86/qaas-kafka-topics)
- **Confluence:** [QaaS Onboarding](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/2113483023) | [QaaS FAQ](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/1801586993) | [QaaS Kafka Application Best Practices](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/1543183705)

## When to Use QaaS vs Other Options

| Use Case                            | Tool                   |
| ----------------------------------- | ---------------------- |
| Async service-to-service messaging  | **QaaS**               |
| Emitting events from game client    | **ESI** → QaaS         |
| Batch data pipelines (hourly/daily) | **Powerhouse/Airflow** |
| Durable long-running workflows      | **Temporal**           |
| High-throughput fan-out             | **QaaS**               |

## Setting Up a Producer (C#)

```csharp
// Startup.cs
services.AddQaasKafkaProducer<MyEvent>(options =>
{
    options.TopicName = "my-team.my-event-topic";
    options.BootstrapServers = config["QaaS:BootstrapServers"];
    // Credentials injected from Vault via Nomad template
    options.Username = config["QaaS:Username"];
    options.Password = config["QaaS:Password"];
});

// In your service
public class MyService
{
    private readonly IKafkaProducer<MyEvent> _producer;

    public async Task PublishAsync(MyEvent evt)
    {
        await _producer.ProduceAsync(evt);
    }
}
```

## Setting Up a Consumer (C#)

```csharp
// Startup.cs
services.AddQaasKafkaConsumer<MyEvent, MyEventProcessor>(options =>
{
    options.TopicName    = "my-team.my-event-topic";
    options.GroupId      = "my-service-consumer-group";
    options.BootstrapServers = config["QaaS:BootstrapServers"];
    options.Username     = config["QaaS:Username"];
    options.Password     = config["QaaS:Password"];
});

// Processor — make it idempotent
public class MyEventProcessor : IKafkaMessageProcessor<MyEvent>
{
    public async Task ProcessAsync(MyEvent message, CancellationToken ct)
    {
        // Process idempotently — message may be delivered more than once
        await _service.HandleAsync(message);
    }
}
```

## Topic Configuration Best Practices

- **Partitions:** Default 5 partitions → max 5 parallel consumers. Scale partitions for higher throughput.
- **Retention:** Set explicit retention (default varies by cluster). Long retention = more storage cost.
- **DLQ:** Always configure a Dead Letter Queue for unprocessable messages. QaaS libraries support DLQ natively.
- **Consumer group:** Use a stable, unique group ID per consuming service.

## Credentials from Vault

QaaS credentials are provisioned via Secrets Broker. Reference them from Nomad template stanzas:

```hcl
template {
  data = <<EOF
{{ with secret "qaas/prod/my-topic/credentials" }}
QAAS_USERNAME={{ .Data.data.username }}
QAAS_PASSWORD={{ .Data.data.password }}
{{ end }}
EOF
  destination = "secrets/env"
  env         = true
}
```

See [Generating New QaaS Users with Secrets Broker Service](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/3753084089).

## Debugging Consumer Lag

Consumer lag means your consumer isn't keeping up with the producer rate.

```promql
# Check lag in Grafana — QaaS Kafka Topics dashboard
# Filter by consumer group and topic
```

Remediation options:

1. **Scale consumers** (add more instances, up to partition count)
2. **Optimize processing** (reduce per-message work, batch processing)
3. **Increase partitions** (requires topic recreation + consumer rebalance)
4. **Reset offset** — use the Kafka CLI reset procedure; see runbook for steps

## Local Testing with a Kafka Cluster

See [How to component test QaaS-based .NET services with a local Kafka cluster](https://roblox.atlassian.net/wiki/spaces/HOW/pages/2185003098) for Docker-based local Kafka setup.
