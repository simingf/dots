---
name: roblox-ixp
description: Set up and run A/B experiments and feature rollouts using Roblox's IXP (Internal Experimentation Platform). Use when creating a new IXP experiment, linking feature flags to an experiment, reading IXP enrollment results in code, analyzing experiment metrics, or running a staged rollout for a new feature in a BEDEV2 service.
---

# IXP — Internal Experimentation Platform

IXP is Roblox's A/B testing and feature rollout system. It controls which users see which feature variants, collects experiment results, and integrates with Obelix feature flags for seamless staged rollouts.

## Key Links

- **IXP Portal:** (internal, search "IXP" on Confluence for the URL)
- **Slack:** `#ixp-users`
- **Confluence:** [IXP, Experimentation, and AB Testing in Studio](https://roblox.atlassian.net/wiki/spaces/HOW/pages/2567012656) | [Best Practices for IXP-flags Experimentation](https://roblox.atlassian.net/wiki/spaces/DA/pages/3523347759) | [A/B Testing, IXP](https://roblox.atlassian.net/wiki/spaces/~71202031de72db21684c5a80b5949a2cba9b49/pages/3395355302)

## Naming Convention

```
<Team>.<Feature>.<Version>
```

Examples:

- `ContentUnderstanding.DeepScanRollout.V1`
- `IpScanner.EaaSFallback.V2`
- `CreatorDocumentation.KnowledgeFeeds.V1`

Use consistent, descriptive names — they appear in dashboards and experiment logs.

## Experiment Setup Workflow

```
1. Create experiment in IXP Portal:
   - Set experiment name (follow naming convention)
   - Define variants (Control, Treatment A, Treatment B...)
   - Set traffic allocation % per variant
   - Optionally set start/end dates

2. Link to a feature flag (Obelix):
   - Attach the IXP experiment to an Obelix FeatureManagement flag
   - IXP controls enrollment; Obelix flag controls code behavior

3. (Optional) Set up a holdout group for long-term measurement

4. Go live → IXP enrolls users on first request

5. Analyze results in Superset or IXP metrics dashboard
```

## Reading IXP Enrollment in C# (BEDEV2)

IXP enrollment is typically handled via the IXP client library:

```csharp
// Startup.cs
services.AddIxpClient();

// In your service — check which variant a user is enrolled in
public class MyService
{
    private readonly IIxpClient _ixp;

    public async Task<Result> HandleRequestAsync(long userId)
    {
        var enrollment = await _ixp.GetEnrollmentAsync(
            experimentName: "ContentUnderstanding.DeepScanRollout.V1",
            subjectId: userId.ToString());

        return enrollment.VariantName switch
        {
            "Treatment" => await HandleTreatmentAsync(userId),
            _           => await HandleControlAsync(userId),
        };
    }
}
```

## Using IXP with Obelix Feature Flags (Preferred Pattern)

For server-side experiments, link the IXP experiment to an Obelix flag — this way enrollment happens server-side and you just gate code with the flag:

```csharp
// The IXP experiment controls the flag rollout percentage.
// Your code just checks the flag:
if (await _featureManager.IsEnabledAsync("ContentUnderstanding.DeepScanRollout.V1"))
{
    // treatment path
}
else
{
    // control path
}
```

## Best Practices

- **Gate all new features** with an IXP flag from day one, even if not running an experiment yet
- **Don't prematurely end** experiments — wait for statistical significance (IXP shows p-values)
- **Run flag canaries first** before starting the IXP experiment to validate no crashes
- **Holdout groups:** for long-term holdouts, set up in IXP Portal before launching
- Treat the IXP experiment like a production release — run standard canary checks first

## Ending an Experiment

1. In IXP Portal: mark experiment as "concluded" + record decision
2. Remove the flag check from code (clean up treatment vs control branching)
3. Keep the winning variant as the default behavior
4. Archive the experiment flag in Obelix

## Common Issues

- **No data flowing:** Verify the experiment is "Live" in IXP Portal, not in "Draft"
- **Imbalanced enrollment:** Check if a hash collision exists; contact `#ixp-users`
- **Metrics not showing:** Data may have a ~1 day lag in Superset; check `MAX(ds)` in your tables
