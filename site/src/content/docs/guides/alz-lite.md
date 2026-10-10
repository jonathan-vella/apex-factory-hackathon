---
title: ALZ-lite
description: The two-subscription model, what's fixed, and how it compares with a full ALZ.
---

This guide covers the mechanics of the kit's landing zone. [C2](../../challenges/c02-secure-ai-ready-foundation/) is the what and the acceptance bar.

## The two-subscription model

Each team uses two kinds of subscription:

- **One shared services subscription**, held by the platform lead. It hosts the hub, the management group hierarchy, central policies and the central Log Analytics workspace.
- **One workload subscription per member**, vended into the hierarchy as a spoke with its own subnets, peering back to the hub, and member-scoped budgets and RBAC.

This mirrors the real distinction between platform-team-owned shared infrastructure and workload-team-owned application resources, at a scale that fits a two-day event.

## What the platform lead needs

The built-in **Owner** role at Tenant Root scope (the script checks for the role named `Owner`, so an equivalent custom role doesn't pass). Without this, `Deploy-AlzLite.ps1` can't create management groups or move subscriptions into them, and the deploy fails early with a clear permissions error.

## One step that needs a directory role

ALZ-lite creates the identity `id-sqlmi-directory` in `rg-management`. Every member's SQL Managed Instance uses it, so `CREATE USER ... FROM EXTERNAL PROVIDER` can look up the web app's identity in C7. Once per team, right after `Deploy-AlzLite.ps1`, someone with the **Privileged Role Administrator** (or Global Administrator) directory role grants it Microsoft Graph read permissions with `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId <id>`. The platform lead usually doesn't hold that role, so arrange it before the event. [C2](../../challenges/c02-secure-ai-ready-foundation/) has the exact step.

## Fixed values

- Region: `swedencentral`, with `germanywestcentral` as the fallback if capacity is constrained.
- Hub address space: `10.100.0.0/16`.
- Azure Firewall: Standard SKU, DNS proxy enabled. No Premium features (TLS inspection, IDPS) — out of scope for a two-day event.
- Defender for Cloud: Foundational CSPM only (free). Paid Defender plans are off — this is a deliberate AI-readiness gap, called out again in [C10](../../challenges/c10-package-hand-over-review-ai-readiness/)'s gap register, not an oversight to silently work around.
- No availability zones pinned, and no zone redundancy explicitly turned on anywhere in the kit. Where a service is zone-redundant automatically with no extra configuration (for example, Azure Container Registry or Azure Service Bus Premium), that's the platform's default behavior, not a kit setting — see the [availability zones reference](../../reference/availability-zones/).

## How it compares with a full ALZ

The coach's live demo in C2 shows a complete portal-deployed Azure Landing Zone. ALZ-lite deliberately narrows that scope for a two-day event:

| Full ALZ | ALZ-lite |
|---|---|
| Platform, Landing Zones, Sandbox and Decommissioned management groups | `mg-factory` (under Tenant Root) with `mg-factory-platform` and `mg-factory-corp` beneath it |
| Multiple landing zone archetypes (Corp, Online, confidential) | One archetype (Corp) |
| Full Azure Policy initiative set (hundreds of built-ins) | A small, fixed set: Audit for location, Deny for public network access/public IPs, DeployIfNotExists for private DNS and diagnostics |
| Defender for Cloud with paid plans | Foundational CSPM only, free |
| Hub with ExpressRoute/VPN gateways | Hub with Azure Firewall only — no on-premises connectivity, since there's no real on-premises network to connect to |

None of these are mistakes in ALZ-lite — they're intentional simplifications for a lab, documented so you know what a real customer engagement would add back.
