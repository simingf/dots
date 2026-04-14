---
name: roblox-vault
description: Manage secrets, credentials, and TLS certificates using HashiCorp Vault at Roblox. Use when fetching a service's API key or database credentials from Vault, setting up mTLS certificates for Temporal or inter-service communication, rotating secrets via Secrets Broker, or debugging a certificate/credential issue in a BEDEV2 service.
---

# Vault — Secrets Management at Roblox

HashiCorp Vault is Roblox's central secrets management and PKI system. All service credentials, Kafka passwords, mTLS certificates, and API keys are stored and rotated through Vault.

## Key Links

- **Vault UI:** `vault.simulprod.com` (prod), `sitetest3-vault.simulpong.com` (ST3)
- **Secrets Broker configs:** `github.rbx.com/Roblox/secrets-broker-configs`
- **Slack:** `#certificates` (PKI/mTLS), `#vault-users` (general)
- **Confluence:** [Secret Management with Vault](https://roblox.atlassian.net/wiki/spaces/OP/pages/1568679952) | [Secrets Broker Service](https://roblox.atlassian.net/wiki/spaces/INFOSEC/pages/2644443301)

## Common Secret Paths

| Secret Type         | Vault Path Pattern                                     |
| ------------------- | ------------------------------------------------------ |
| Service API keys    | `secrets_apps_kv/<service-name>/<key>`                 |
| QaaS Kafka creds    | `qaas/<env>/<topic>/credentials`                       |
| Temporal mTLS certs | provisioned via PKI engine, available via cert probing |
| DB passwords        | `database/<env>/<service>/creds/<role>`                |

## Reading a Secret from a BEDEV2 Service (C#)

Vault secrets are typically injected as environment variables via Nomad's `template` stanza — you don't read Vault directly in code at runtime.

```hcl
# In your job.nomad template stanza:
template {
  data = <<EOF
{{ with secret "secrets_apps_kv/my-service/api-key" }}
MY_API_KEY={{ .Data.data.value }}
{{ end }}
EOF
  destination = "secrets/env"
  env         = true
}
```

Then in C#:

```csharp
var apiKey = Environment.GetEnvironmentVariable("MY_API_KEY");
```

## Secrets Broker (Auto-rotation)

For **static secrets that need rotation**, use the Secrets Broker instead of managing rotation manually.

```yaml
# secrets-broker-configs/onboarding-configs/my-service.yaml
source:
  vault_path: "secrets_apps_kv/upstream-service/api-key"
  vault_cluster: "prod"
destination:
  vault_path: "secrets_apps_kv/my-service/upstream-api-key"
  vault_cluster: "prod"
rotation_schedule: "0 0 * * 0" # weekly
```

Open a PR to `Roblox/secrets-broker-configs` — no code changes needed.
See: [Secrets Broker Service](https://roblox.atlassian.net/wiki/spaces/INFOSEC/pages/2644443301)

## mTLS Certificates (for Temporal, inter-service)

Vault's PKI engine issues mTLS certs. For Temporal workers:

- Certs are provisioned automatically for BD2 services via cert probing
- For MLP/notebook usage: upload certs manually (see CUP onboarding)
- Ask `#certificates` if you need a new PKI engine or cert path

```csharp
// Loading mTLS cert in a Temporal worker (base64-encoded env var approach)
var certBytes = Convert.FromBase64String(
    Environment.GetEnvironmentVariable("TEMPORAL_MTLS_CERT_BASE64")!);
var keyBytes = Convert.FromBase64String(
    Environment.GetEnvironmentVariable("TEMPORAL_MTLS_KEY_BASE64")!);
```

## CLI Access (for debugging)

```bash
# Authenticate
vault login -method=ldap username=yourname

# Read a secret
vault kv get secrets_apps_kv/my-service/api-key

# List secrets at a path
vault kv list secrets_apps_kv/my-service/
```

## Common Issues

- **Secret not found:** Check the path casing — paths are case-sensitive
- **Permission denied:** Your service's Vault policy may not include the path; file a ticket in `#vault-users`
- **Cert expired:** Ask `#certificates` to re-issue; Secrets Broker can auto-rotate if configured
