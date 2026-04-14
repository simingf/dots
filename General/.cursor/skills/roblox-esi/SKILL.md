---
name: roblox-esi
description: Send events to Kafka using Experience Signals Ingest (ESI) at Roblox. Use when instrumenting a service to emit events, defining a new event proto schema, integrating ESI into a C# or Go service, choosing between gRPC and HTTP ESI endpoints, or debugging event ingestion issues.
---

# Experience Signals Ingest (ESI)

ESI is Roblox's event ingestion gateway — the replacement for EventForwarder. It accepts schematized proto events from any calling context and publishes them to Kafka. Optionally, events flow to the data lake via Kafka Tailer.

## Key Links

- **Service repo:** `github.rbx.com/Roblox/experience-signals-ingest`
- **Event schemas:** `github.rbx.com/Roblox/proto-schemas`
- **API proto:** `github.rbx.com/Roblox/service-contracts` → `protos/roblox/creatoreventsexport/experiencesignalsingest/v1/`
- **Confluence:** [ESI Getting Started](https://roblox.atlassian.net/wiki/spaces/data/pages/2864218364)
- Onboarding guides: [C#](https://roblox.atlassian.net/wiki/x/N4Cgzw) | [Go](https://roblox.atlassian.net/wiki/x/S4Cgzw) | [Python](https://roblox.atlassian.net/wiki/x/JIDj4w) | [TS/JS](https://roblox.atlassian.net/wiki/x/iYIp1w)

## Step 1 — Define Your Event in proto-schemas

```protobuf
// proto-schemas/production/eventstream/esp/<team>/<event_name>.proto
syntax = "proto3";
package eventstream.esp.myteam;

message MyEvent {
  int64 universe_id = 1;
  float score = 2;
  string reason = 3;
  int64 timestamp_ms = 4;
}
```

The fully-qualified name (FQN) `eventstream.esp.myteam.MyEvent` becomes the `source` field in ESI calls.

## Step 2 — Choose Protocol & Endpoint

Prefer **gRPC** from internal services. Use **HTTP** from RCC/game servers or public contexts.

| Context                      | Base URL                                                   |
| ---------------------------- | ---------------------------------------------------------- |
| Internal (BD2 service)       | `https://apis.simulprod.com/experience-signals-ingest`     |
| Privileged (RCC/game server) | `https://apis.roblox.com/experience-signals-ingest/rcc`    |
| Public                       | `https://apis.roblox.com/experience-signals-ingest/public` |

## Step 3 — Send Events (C# gRPC Example)

```csharp
// In Startup.cs
services.AddGrpcClient<ExperienceSignalsIngestApi.ExperienceSignalsIngestApiClient>(o =>
{
    o.Address = new Uri("https://apis.simulprod.com/experience-signals-ingest");
});

// Emit events (batch preferred: 256KB–1MB per batch)
public async Task EmitEventsAsync(IEnumerable<MyEvent> events)
{
    var fqn = "eventstream.esp.myteam.MyEvent";
    var request = new SendUniformBatchRequest { Source = fqn };
    request.Payloads.AddRange(events.Select(e => e.ToByteString()));

    await _esiClient.SendUniformBatchAsync(request);
}
```

## Send Methods (ranked by efficiency)

| Method               | Endpoint               | When to Use                          |
| -------------------- | ---------------------- | ------------------------------------ |
| `SendUniformBatch`   | `/v1/events/uniform`   | All events same type — **preferred** |
| `SendOptimizedBatch` | `/v1/events/optimized` | Few different event types            |
| `SendBatch`          | `/v1/events`           | Many different event types           |
| `SendEvent`          | `/v1/events/single`    | Single event — avoid at scale        |

Target batch size: **256 KB – 1 MB** per request.

## Limits

- Max request payload: **4 MB** (protobuf serialized)
- Max single event: **1 MB**

## Retry Policy

- **Do NOT retry** 2XX or 4XX responses
- Retry 5XX responses (transient failures)
- For guaranteed delivery: add header `Delivery-Guarantee: at-least-once` (high latency cost — use only when truly needed)

## Enabling Data Lake Write (Kafka Tailer)

In your proto-schema definition, set the Kafka Tailer option to write events to the data lake. This is configured in the proto-schemas repo alongside the event definition.

## Debugging

- ESI obfuscates error messages for unauthenticated callers
- From internal services: set `Roblox-Api-Key` header (registered in `apicontrolplane-configuration`) to see detailed errors
- Check event delivery in Kafka topic: `eventstream.esp.myteam.myevent`
