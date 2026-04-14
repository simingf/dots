---
name: roblox-eaas
description: Provision and use Entities-as-a-Service (EaaS) for online data storage at Roblox. Use when creating or modifying EaaS entity schemas, adding new entity groups, writing C# service code that reads/writes EaaS data, debugging EaaS queries, or working with storage-resources provisioning.
---

# Entities-as-a-Service (EaaS)

EaaS is Roblox's managed online datastore — a self-service gRPC interface over CockroachDB. Consumers declare schemas in YAML; EaaS generates the gRPC API and manages the DB entirely.

## Key Links

- **Schema/provisioning repo:** `github.rbx.com/Roblox/storage-resources`
- **Confluence:** [EaaS Offering and Introduction](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/1543180281) | [Schema Reference](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/2351989819)
- **Slack:** `#dbplat-access` (non-prod) | PagerDuty `PN6HBYZ` (prod)
- **Dashboard:** `go/entities` → Grafana
- **CLI/GUI:** Download from Artifactory for debugging entity data

## Creating a New Entity Group

1. Add a YAML schema file in `storage-resources` under your team's directory
2. Open a PR — provisioning is fully declarative
3. Recommended: **1:1 mapping** between entity group and consuming service

```yaml
# storage-resources/teams/my-team/my-entity-group/schema.yaml
entityGroup: my-entity-group
owner: my-service
entities:
  - name: MyRecord
    fields:
      - name: id
        type: string
        maxLength: 64
      - name: score
        type: float
      - name: createdAt
        type: timestamp
    operations:
      - create
      - get
      - update
      - delete
```

## Accessing EaaS from C# (BEDEV2)

```csharp
// In Startup.cs — inject the generated EaaS client
services.AddEntitiesClient<IMyEntityGroupClient>(config =>
{
    config.EntityGroupName = "my-entity-group";
});

// In your service
public class MyService
{
    private readonly IMyEntityGroupClient _entities;

    public MyService(IMyEntityGroupClient entities) => _entities = entities;

    public async Task StoreResultAsync(string id, float score)
    {
        await _entities.MyRecord.CreateAsync(new MyRecord { Id = id, Score = score });
    }

    public async Task<MyRecord?> GetResultAsync(string id)
    {
        return await _entities.MyRecord.GetAsync(id);
    }
}
```

See also: [How to Access Entities Api from a BEDEV2 C# Application](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/1543179628)

## Caching Behavior

- EaaS handles **remote caching** automatically
- **Immutable entities** (create-only, no update/delete) get **local caching** automatically
- Do not add a caching layer on top of EaaS without consulting `#dbplat-access`

## Capacity Planning Triggers (per node)

| Metric      | Threshold for dedicated cluster |
| ----------- | ------------------------------- |
| Reads/sec   | > 2,000                         |
| Writes/sec  | > 500                           |
| Data volume | > 2,100 GiB                     |

Fill out the [CockroachDB Onboarding Capacity Planning](https://docs.google.com/spreadsheets/d/1y9IjA9IKTfxaUj2NXIwZgQyaSUZQiK8bxnPpg5dibQk) if over these limits.

## Schema Change Rules

- Supported live changes: adding nullable fields, adding new operations
- Breaking changes (field removal, type changes) require migration planning
- See [Supported Live Schema Updates](https://roblox.atlassian.net/wiki/spaces/DBPLAT/pages/1543180281)

## Debugging

Use the EaaS CLI/GUI (download from Artifactory) to read data directly from an entity group without writing service code.
