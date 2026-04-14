---
name: roblox-obelix
description: Add, read, or modify runtime configuration and feature flags for BEDEV2 services using Obelix at Roblox. Use when adding a new config setting to a C# service, creating a feature flag, changing a threshold without redeploying, debugging why a config value isn't updating, or setting up runtime configuration for a new service.
---

# Obelix — BEDEV2 Runtime Configuration

Obelix is the GUI and system for dynamic runtime configuration of BEDEV2 services. It lets you change knobs and feature flags without redeploying. Backed by the **Orbiter** service (serves configs) with S3 as the master store.

## Key Links

- **UI:** `obelix.simulprod.com/project/<product>/runtime-configuration/group/<service>`
- **Confluence:** [1021 - Runtime Configuration](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531874854) | [1021.1 - Using Obelix GUI](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531871979) | [1021.2 - Set up Runtime Config in a Service](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531872022)

## Setting Up Runtime Config in C# (BEDEV2)

```csharp
// 1. Define your settings class
public class MyServiceSettings
{
    public int MaxCandidates { get; set; } = 500;
    public bool EnableDeepScan { get; set; } = false;
    public double ScoreThreshold { get; set; } = 0.75;
}

// 2. Register in Startup.cs
services.AddRuntimeConfiguration<MyServiceSettings>(
    projectName: "creator-content-search",
    groupName: "ip-scanner");

// 3. Inject and use in your service
public class MyService
{
    private readonly IOptionsMonitor<MyServiceSettings> _settings;

    public MyService(IOptionsMonitor<MyServiceSettings> settings)
        => _settings = settings;

    public int GetMaxCandidates()
        => _settings.CurrentValue.MaxCandidates; // reads live value
}
```

## Adding a Setting in Obelix UI

1. Go to `obelix.simulprod.com/project/<product>/runtime-configuration/group/<service>`
2. Click **Add Setting**
3. Enter the property name (must match your C# class property exactly)
4. Set default value and optionally per-environment overrides
5. Save — the service picks up the new value within ~30 seconds (no redeploy needed)

## Feature Flags with `Microsoft.FeatureManagement`

```csharp
// Startup.cs
services.AddFeatureManagement()
    .UseRuntimeConfiguration(projectName: "creator-content-search",
                             groupName:   "ip-scanner");

// Define flag names as constants
public static class FeatureFlags
{
    public const string EnableFrostFallback = "EnableFrostFallback";
    public const string UseEaaSForDeepScan  = "UseEaaSForDeepScan";
}

// Use in service
public class ScanService
{
    private readonly IFeatureManager _features;

    public async Task<Result> ScanAsync(Request req)
    {
        if (await _features.IsEnabledAsync(FeatureFlags.UseEaaSForDeepScan))
            return await ScanViaEaaSAsync(req);

        return await ScanViaFrostAsync(req);
    }
}
```

Rollout strategies available in Obelix: percentage rollout, user-based, time-based, and custom filters.

## Obelix URL Pattern

```
# Find your service's Obelix config:
https://obelix.simulprod.com/project/{product}/runtime-configuration/group/{service}

# Examples:
https://obelix.simulprod.com/project/creator-content-search/runtime-configuration/group/ip-scanner
https://obelix.simulprod.com/project/creator-cu/runtime-configuration/group/experience-deep-scan-workflow
```

## Using Obelix in a BEDEV2 Library

If you're building a shared library, inject settings via the library's own group rather than the consumer's:

```csharp
// In your library's ServiceCollectionExtensions
public static IServiceCollection AddMyLibrary(
    this IServiceCollection services,
    string projectName)
{
    services.AddRuntimeConfiguration<MyLibrarySettings>(
        projectName: projectName,
        groupName: "my-library"); // library-owned group
    return services;
}
```

See: [1021.3 - Using Runtime Configuration in a BEDEV2 Lib](https://roblox.atlassian.net/wiki/spaces/BEDEV2/pages/1531873017)

## Common Issues

- **Setting not updating:** Check Orbiter is healthy; settings propagate in ~30s
- **Property name mismatch:** Obelix key must exactly match the C# property name (case-sensitive)
- **Value ignored:** Ensure `IOptionsMonitor<T>` is used, not `IOptions<T>` (the latter is snapshot-at-startup)
