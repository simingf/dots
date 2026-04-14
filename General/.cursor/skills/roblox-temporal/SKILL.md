---
name: roblox-temporal
description: Write Temporal workflows and activities for Roblox BEDEV2 services. Use when building durable workflows, replacing SQS processors or Overseer, setting up a Temporal worker in a C# service, handling workflow non-determinism, debugging failed workflows in Temporal Cloud UI, or onboarding a new Temporal namespace at Roblox.
---

# Temporal at Roblox

Temporal is Roblox's workflow orchestration engine for durable, fault-tolerant business logic. Workers run as BEDEV2 services; payloads are encrypted via Infra's Workflow Proxy before leaving Roblox DCs.

## Key Links

- **Temporal Cloud UI:** `cloud.temporal.io`
- **Confluence:** [Temporal Primer (CU)](https://roblox.atlassian.net/wiki/spaces/CU/pages/3451585455) | [Temporal.io Homepage (Infra)](https://roblox.atlassian.net/wiki/spaces/IF/pages/2910945352) | [Onboarding Guide](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/3113648431)
- **Reference worker:** `github.rbx.com/Roblox/content-understanding-platform/tree/master/services/cup-temporal-worker`
- **Hello World:** `github.rbx.com/Roblox/storage-resources-demo`
- **Slack:** `#roblox-workflow-users`

## Core Concepts

| Concept        | Description                                                                                     |
| -------------- | ----------------------------------------------------------------------------------------------- |
| **Namespace**  | Team-scoped isolation unit; provision one per team                                              |
| **Workflow**   | Code-defined durable process (must be **deterministic**)                                        |
| **Activity**   | Individual task within a workflow; can interact with external systems; **should be idempotent** |
| **Worker**     | BD2 service that polls Temporal Server and executes workflows/activities                        |
| **Task Queue** | Named queue that routes workflow/activity tasks to the right workers                            |

## Setting Up a Temporal Worker (C#)

```csharp
// Startup.cs — register Temporal worker as a hosted service
services.AddHostedService<MyTemporalWorker>();
services.AddTemporalClient(options =>
{
    options.TargetHost = config["Temporal:ProxyHost"]; // Infra's Workflow Proxy
    options.Namespace = "my-team-prod.leybd";
    options.Tls = new TlsConfig { /* mTLS certs from Vault */ };
});

// Auto-register all workflows & activities from assembly
services.AddTemporalWorkersFromAssembly(typeof(Startup).Assembly);
```

```csharp
// MyTemporalWorker.cs
public class MyTemporalWorker : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        var worker = new TemporalWorker(client, new TemporalWorkerOptions("my-task-queue")
            .AddAllActivities(serviceProvider)
            .AddWorkflow<MyWorkflow>());
        await worker.ExecuteAsync(ct);
    }
}
```

## Writing a Workflow

```csharp
[Workflow]
public class MyWorkflow
{
    // Workflows MUST be deterministic — no random, no DateTime.Now, no I/O
    // All external calls must go through Activities
    [WorkflowRun]
    public async Task<MyResult> RunAsync(MyInput input)
    {
        // Step 1: collect data
        var data = await Workflow.ExecuteActivityAsync(
            (IMyActivities a) => a.CollectDataAsync(input.Id),
            new ActivityOptions { StartToCloseTimeout = TimeSpan.FromMinutes(5) });

        // Step 2: process
        var result = await Workflow.ExecuteActivityAsync(
            (IMyActivities a) => a.ProcessDataAsync(data),
            new ActivityOptions
            {
                StartToCloseTimeout = TimeSpan.FromMinutes(10),
                RetryPolicy = new RetryPolicy { MaximumAttempts = 3 }
            });

        return result;
    }
}
```

## Writing Activities

```csharp
[Activity]
public class MyActivities : IMyActivities
{
    // Activities CAN do I/O, call external services, be retried
    // Make them IDEMPOTENT — they may run more than once
    public async Task<CollectedData> CollectDataAsync(string id)
    {
        return await _externalService.FetchAsync(id);
    }
}
```

## Non-Determinism Rules (critical)

Workflows replay their history on each task — breaking determinism causes panics and blocks deployments.

- **Never use:** `DateTime.Now`, `Random`, direct I/O, `Thread.Sleep`, non-deterministic collections
- **Use instead:** `Workflow.UtcNow`, `Workflow.Random`, activities for all external calls, `await Workflow.DelayAsync()`
- When **adding a new activity** to a running workflow: version it with `Workflow.GetVersion()` to avoid non-determinism errors on in-flight workflows

## Cross-Namespace Calls (until Nexus .NET support)

Expose a gRPC endpoint that kicks off a Temporal workflow (inspired by `google.longrunning.operations`):

```csharp
// Controller that allows other teams to trigger your workflow
[GrpcService]
public class MyWorkflowApiService
{
    public async Task<Operation> ExecuteMyWorkflow(ExecuteRequest req)
    {
        var handle = await _temporalClient.StartWorkflowAsync(
            (MyWorkflow wf) => wf.RunAsync(new MyInput { Id = req.Id }),
            new WorkflowOptions { Id = $"my-workflow-{req.Id}", TaskQueue = "my-task-queue" });

        return new Operation { Id = handle.Id };
    }

    public async Task<OperationStatus> GetOperation(GetOperationRequest req)
    {
        var handle = _temporalClient.GetWorkflowHandle(req.Id);
        var desc = await handle.DescribeAsync();
        return MapToStatus(desc.Status);
    }
}
```

## Useful Temporal Cloud UI Queries

```
# Find workflows of a specific type
WorkflowType="DeepScanWorkflow"

# Find failed workflows in the last hour
WorkflowType="MyWorkflow" AND ExecutionStatus="Failed" AND StartTime > "2025-01-01T00:00:00Z"
```

## What Temporal Does NOT Replace

- **Airflow** — hourly/daily batch ETL; Temporal is for event-driven, per-entity workflows
- **Kubeflow** — ML training pipelines with GPU scheduling
- **Ray** — distributed parallel compute
- **Flink** — stateful stream processing

## Reference Worker Code

See `github.rbx.com/Roblox/content-understanding-platform/tree/master/services/cup-temporal-worker` for a production-ready Roblox Temporal worker with encryption codec, mTLS setup, and hosted worker pattern.
