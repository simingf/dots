---
name: roblox-grasshopper
description: Create and consume shared npm packages from Roblox's Grasshopper monorepo for web frontend development. Use when adding a new @rbx/* package to Grasshopper, consuming a Grasshopper package in a web app, following Roblox web package standards, or reviewing whether an existing package already covers a use case.
---

# Grasshopper — Roblox Shared Web Packages

Grasshopper is Roblox's monorepo of shared `@rbx/*` npm packages for web frontend development. It is led by Creator Resources Foundation with distributed ownership per package.

## Key Links

- **Repo:** `github.rbx.com/Roblox/grasshopper`
- **CODEOWNERS:** `github.rbx.com/Roblox/grasshopper/blob/master/CODEOWNERS`
- **Confluence:** [Grasshopper Overview](https://roblox.atlassian.net/wiki/spaces/CREATORSUCCESS/pages/1961789849)

## Before Creating a New Package

Check if a suitable package already exists in Grasshopper or the broader npm ecosystem. Only create a new `@rbx/*` package if:

1. There is no existing open-source library that fits
2. The logic is genuinely reusable across multiple Roblox web apps
3. You've written a technical spec justifying the need

## Package Standards (required)

| Standard       | Requirement                                                     |
| -------------- | --------------------------------------------------------------- |
| **Composable** | Single responsibility; expose state to consumers                |
| **Semantic**   | Explicit names, no pseudonyms, fully searchable                 |
| **Compatible** | Works with NextJS browserlists, CJS + ESM formats, tree-shaking |
| **Consistent** | Follows existing `@rbx` best practices                          |

## Adding a New Package

```
grasshopper/
└── packages/
    └── my-new-package/
        ├── package.json
        ├── src/
        │   └── index.ts
        ├── tsconfig.json
        └── README.md
```

```json
// package.json
{
  "name": "@rbx/my-new-package",
  "version": "1.0.0",
  "main": "dist/cjs/index.js",
  "module": "dist/esm/index.js",
  "types": "dist/types/index.d.ts",
  "peerDependencies": {
    "react": "^18.0.0"
  }
}
```

Key rules for dependencies:

- **Production deps** → use `peerDependencies` (consumers provide them)
- **Exception:** if your package wraps another lib (e.g., `@rbx/ui` over `mui`), list the wrapped lib as a regular dependency — and consumers should use _only_ your wrapper
- No restrictions on `devDependencies`

## Consuming a Grasshopper Package

```bash
npm install @rbx/clients
# or
yarn add @rbx/thumbnails
```

```typescript
import { RobloxClient } from "@rbx/clients";
import { getThumbnail } from "@rbx/thumbnails";

// @rbx/thumbnails automatically batches + caches thumbnail requests
const thumbnail = await getThumbnail({ assetId: 12345 });
```

## Common Packages

| Package           | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| `@rbx/clients`    | Make authenticated requests to Roblox API endpoints |
| `@rbx/thumbnails` | Batched + cached calls to the Thumbnails API        |
| `@rbx/auth`       | Authentication helpers                              |

## Limitations

- Grasshopper does **not** support static assets or translations — handle those in your app directly
- Packages must support NextJS browserlists/polyfills by default; document deviations in a compatibility guide

## Adding Yourself as CODEOWNER

When creating a new package, add yourself to `CODEOWNERS` for that package's path:

```
/packages/my-new-package/ @your-github-username
```
