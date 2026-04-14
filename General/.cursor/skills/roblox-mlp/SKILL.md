---
name: roblox-mlp
description: Use Roblox's Machine Learning Platform (MLP) for model training, notebook-based R&D, and online model serving. Use when calling an ML model from a C# service, deploying a new model to MLP serving, setting up a Kubeflow notebook for experimentation, debugging model serving latency, or onboarding a model to the models-as-a-service GitOps deployment.
---

# MLP — Machine Learning Platform

MLP is Roblox's internal ML infrastructure built on Kubeflow. It provides Jupyter notebook servers for R&D, model training pipelines, and online model serving (KFServing/KServe). The Deep Scan workflow uses MLP for SigLIP embedding inference.

## Key Links

- **MLP docs site:** `pages.github.rbx.com/Roblox/ml-client` (VPN required)
- **Models-as-a-service repo:** `github.rbx.com/Roblox/models-as-a-service`
- **C# client lib:** `github.rbx.com/Roblox/machine-learning-platform-dotnet-libraries`
- **Slack:** `#mlp-users`
- **Confluence:** [MLP FAQs for users](https://roblox.atlassian.net/wiki/spaces/MLI/pages/3074228271) | [MLP Serving Runbook](https://roblox.atlassian.net/wiki/spaces/MLI/pages/1784578349) | [creator-cu MLP models runbook](https://roblox.atlassian.net/wiki/spaces/CU/pages/2559082906)

## Architecture

```
R&D (MLP Kubeflow Notebooks)
    ↓ model trained + evaluated
Model Registry (MLflow or similar)
    ↓ model promoted to production
models-as-a-service (GitOps deployment)
    ↓ deployed to
KFServing/KServe (model serving endpoint)
    ↓ called by
BD2 service (via MLP C# client library → gRPC)
```

## Calling a Model from C# (BEDEV2)

```csharp
// Startup.cs — register MLP inference client
services.AddMlpInferenceClient(options =>
{
    options.InferenceUrl = config["Mlp:InferenceUrl"];
    // e.g. "ml-platform-prod-us-east-1-1-6-1.prod.ml.rbx.com"
});

// In your service — call the model
public class DeepScanService
{
    private readonly IInferenceClient _mlpClient;

    public async Task<EmbeddingResponse> GetEmbeddingAsync(byte[] imageBytes)
    {
        var request = new InferenceRequest
        {
            ModelName = "siglip-image-ensemble",
            Inputs = new[] { new InferenceInput { Data = imageBytes } }
        };
        return await _mlpClient.InferAsync(request);
    }
}
```

See `IInferenceClient` interface: `machine-learning-platform-dotnet-libraries/libs/inference-util/src/Interfaces/IInferenceClient.cs`

## Active Models Used by Content Understanding

| Model                         | MLP Name                | Used By                           |
| ----------------------------- | ----------------------- | --------------------------------- |
| SigLIP image embeddings       | `siglip-image-ensemble` | Deep Scan worker, content-signals |
| VLM (vision-language) scoring | varies                  | Deep Scan worker                  |

Grafana dashboard: [MLP Model Serving](https://grafana.rbx.com/d/CM7DWYanzCopy/mlp-model-serving)
Filter by: `namespace=kubeflow-creator-cu`, `service_name=siglip-image-ensemble-predictor-default`

## Deploying a New Model (models-as-a-service)

All new production model deployments go through GitOps via `Roblox/models-as-a-service`:

```yaml
# models-as-a-service/models/my-model/production.yaml
apiVersion: serving.kubeflow.org/v1beta1
kind: InferenceService
metadata:
  name: my-model-predictor
  namespace: kubeflow-creator-cu
spec:
  predictor:
    containers:
      - name: kfserving-container
        image: artifactory.rbx.com/my-team/my-model:v1.2.3
        resources:
          requests:
            cpu: "4"
            memory: "8Gi"
```

Open a PR to `Roblox/models-as-a-service` — no manual kubectl apply.

## Notebook Setup (R&D)

1. Go to the MLP portal (see MLP docs site)
2. Create a notebook server in namespace `kubeflow-<team>`
3. Select resources (CPU/GPU/memory)
4. For Temporal-integrated workflows (like Deep Scan research): upload Vault mTLS certs to the notebook

## Scaling Model Serving

```bash
# Emergency scale-up (from ml-model-serving repo)
swarp scale production
# Follow prompts to increase replica count
```

Or edit the `models-as-a-service` manifest and open a PR for the standard GitOps path.

See: [How to scale MLP model serving](https://roblox.atlassian.net/wiki/spaces/AMSD/pages/3529933857)

## Common Issues

- **Model not starting:** Check notebook server status in MLP portal; look for OOM (out-of-memory) errors
- **High inference latency:** Scale up replicas via `swarp scale production` for emergency, or `models-as-a-service` PR for permanent
- **Noisy neighbors:** Model serving allocations pin to specific logical processors — if you see CPU throttling, check for co-located high-CPU jobs
- **inferenceUrlOverride:** For testing against a different model version, pass `inferenceUrlOverride` to the C# client
