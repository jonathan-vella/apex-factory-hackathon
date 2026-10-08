# 📦 SKU Manifest - university

![Artifact](https://img.shields.io/badge/Artifact-SKU%20Manifest-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Draft-orange?style=for-the-badge)
![Schema](https://img.shields.io/badge/Schema-sku--manifest--v1-purple?style=for-the-badge)

<details open>
<summary><strong>📑 Manifest Contents</strong></summary>

- [Overview](#overview)
- [Environments](#environments)
- [Services](#services)
- [Revision History](#revision-history)
- [Open Substitutions](#open-substitutions)

</details>

> Rendered from `sku-manifest.json` (rev 3) by `tools/scripts/render-sku-manifest-md.mjs`.
>
> **Do not hand-edit this file.** Mutate `sku-manifest.json` and re-run
> the renderer (wired into lefthook + CI). Authoring rules:
> [`.github/instructions/sku-manifest.instructions.md`](../../.github/instructions/sku-manifest.instructions.md).

## Overview

| Field            | Value                                                      |
| ---------------- | ---------------------------------------------------------- |
| Project          | `university`                                        |
| Default region   | `swedencentral` (per-service `regions[]` inherits this) |
| Schema version   | `sku-manifest-v1`                                          |
| Current revision | `3`                               |
| Last updated     | `2026-10-06T14:50:00Z`                                     |
| Environments     | `dev` (comma-separated)                              |
| Service count    | `5`                                        |

**Scope**: creative SKU decisions only — App Service plans, VMs/VMSS, SQL,
Cosmos, AKS pools, Redis, APIM, App Gateway, Storage replication tiers.

**Out of scope** (do not add to `services[]`): bandwidth, Log Analytics,
vnet, subnet, NSG, route table, public IP, diagnostics. See
[`.github/instructions/sku-manifest.instructions.md`](../../.github/instructions/sku-manifest.instructions.md).

## Environments

| Environment | In scope | Notes |
| ----------- | -------- | ----- |
| `dev` | ✅ | — |

## Services

> Rendered from `sku-manifest.json` `services[]`. Per-environment values
> reflect `environment_overrides` on top of the base entry.

| `id` | Service | Size (base) | Capacity | Zonal | Regions | SLA target / achieved | Commitment | Source | Rev |
| ---- | ------- | ----------- | -------- | ----- | ------- | --------------------- | ---------- | ------ | --- |
| `app-service-plan` | App Service Plan | `P0v3` | `fixed (default 1)` | ❌ | `swedencentral`, `germanywestcentral` | `best-effort (no target)` / `No availability commitment claimed: best-effort target; single instance, no zone redundancy, single region.` | `on-demand` | `user-pin` | `3` |
| `container-registry` | Container Registry | `Premium` | `fixed (default 1)` | ❌ | `swedencentral`, `germanywestcentral` | `best-effort (no target)` / `No availability commitment claimed: best-effort target; platform zone redundancy applies automatically, single region.` | `on-demand` | `user-pin` | `3` |
| `service-bus` | Service Bus Namespace | `Premium` | `fixed (default 1)` | ❌ | `swedencentral`, `germanywestcentral` | `best-effort (no target)` / `No availability commitment claimed: best-effort target; Premium 1 MU with platform zone redundancy, single region.` | `on-demand` | `user-pin` | `3` |
| `sql-managed-instance` | SQL Managed Instance | `GP_Gen5` | `fixed (default 1)` | ❌ | `swedencentral`, `germanywestcentral` | `best-effort (no target)` / `No availability commitment claimed: best-effort target; General Purpose single instance, no zone redundancy, Local backup redundancy; unavailable while stopped by schedule after C7.` | `on-demand` | `user-pin` | `3` |
| `storage-account` | Storage Account | `Standard_LRS` | `fixed (default 1)` | ❌ | `swedencentral`, `germanywestcentral` | `best-effort (no target)` / `No availability commitment claimed: best-effort target; LRS, single region.` | `on-demand` | `user-pin` | `3` |

### Per-environment overrides

_No services declare environment overrides._

### Feature requirements

| `id` | `requires[]` | Verified at Step 4 |
| ---- | ------------ | ------------------ |
| `app-service-plan` | `vnet-integration`, `managed-identity` | ✅ / ❌ |
| `container-registry` | `private-endpoints`, `managed-identity` | ✅ / ❌ |
| `service-bus` | `private-endpoints`, `managed-identity` | ✅ / ❌ |
| `sql-managed-instance` | `managed-identity` | ✅ / ❌ |
| `storage-account` | `private-endpoints` | ✅ / ❌ |

### Cost estimate (USD/month)

> Populated by `cost-estimate-subagent` via `manifest_writeback[]` —
> Architect never types prices from parametric knowledge.

| `id` | `cost_estimate_monthly_usd` | Confidence |
| ---- | --------------------------- | ---------- |
| `app-service-plan` | `$64.97` | `—` |
| `container-registry` | `$50.69` | `—` |
| `service-bus` | `$677.08` | `—` |
| `sql-managed-instance` | `$497.68` | `—` |
| `storage-account` | `$1.08` | `—` |

## Revision History

> Append-only. Each row is metadata about a git commit / apex-recall checkpoint.

| `rev` | Step | Agent | Created (UTC) | Summary | Changed `id`s | Commit | Checkpoint |
| ----- | ---- | ----- | ------------- | ------- | ------------- | ------ | ---------- |
| `1` | `1` | `02-Requirements` | `2026-10-05T15:00:00Z` | User pins from the B09 archetype brief for every service class; on-demand only, single dev environment, no zones; approved regions swedencentral + germanywestcentral. | `app-service-plan`, `container-registry`, `sql-managed-instance`, `storage-account`, `service-bus` | — | `university:1:phase_5_artifact` |
| `2` | `2` | `03-Architect` | `2026-10-06T07:10:00Z` | Step 2 review of user pins: all five pins kept unchanged (no candidate sets; every class pinned). Verified P0v3 regional VNet integration and regional offer of every SKU in swedencentral and germanywestcentral. Added architect-computed sla_achieved. Single-region deployment in the hub region; the second approved region is an alternate, not a second deployment. Prices written back by cost-estimate-subagent. | `app-service-plan`, `container-registry`, `sql-managed-instance`, `storage-account`, `service-bus` | `4309ccf` | `university:2:phase_2.5_compacted` |
| `3` | `4` | `05-IaC Planner` | `2026-10-06T14:50:00Z` | Step 4 governance reconciliation: all five user pins kept unchanged; no discovered Deny or SKU allow-list constrains them. requires[] cross-check passes (P0v3 vnet-integration; ACR Premium, StorageV2, Service Bus Premium private-endpoints; managed-identity on all). IaC values set explicitly over AVM defaults: App Service plan skuCapacity 1, zoneRedundant false (AVM default 3/true); Storage skuName Standard_LRS (AVM default Standard_GRS); Service Bus skuObject Premium capacity 1 (AVM default 2); SQL MI zoneRedundant false (raw). AVM-forced zone redundancy accepted and recorded: container-registry 0.13.1 zoneRedundancy Enabled, service-bus 0.17.1 zoneRedundant true (platform-automatic in swedencentral). | `app-service-plan`, `container-registry`, `sql-managed-instance`, `storage-account`, `service-bus` | `5cc66af` | `university:4:phase_3_plan` |

## Open Substitutions

> Captured at Step 6 (Deploy) when a planned SKU is unavailable due to
> quota / region capacity. Mirrors `decisions.sku_overrides[]` in
> `00-session-state.json`.

> **None open** — all SKUs deployed as planned.

---

## References

- Schema: [`tools/schemas/sku-manifest.schema.json`](../../tools/schemas/sku-manifest.schema.json)
- Authoring rules: [`.github/instructions/sku-manifest.instructions.md`](../../.github/instructions/sku-manifest.instructions.md)
- Renderer: `node tools/scripts/render-sku-manifest-md.mjs <project>`
- Validators: `npm run validate:sku-manifest` + `npm run validate:sku-iac-coverage`
