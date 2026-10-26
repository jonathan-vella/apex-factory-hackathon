---
title: ALZ-lite
description: The two-subscription model, what the deploy creates, what's fixed, and how it compares with a full ALZ.
sidebar:
  order: 2
---

This guide covers the mechanics of the kit's landing zone. [C2](../../challenges/c02-secure-ai-ready-foundation/) is the what, the commands the platform lead runs before the event, and the acceptance bar for the day-one walk-through.

## The two-subscription model

Each team uses two kinds of subscription:

- **One shared services subscription**, held by the platform lead. It hosts the hub, the management group hierarchy, central policies and the central Log Analytics workspace.
- **One workload subscription per member**, vended into the hierarchy as a spoke with its own subnets, peering back to the hub, and member-scoped budgets and RBAC. (Vending is connecting a subscription to the hub: spoke network, peering, DNS, firewall rules, budget. The hub is the shared virtual network; a spoke is a member's network that peers with it.)

This mirrors the real distinction between platform-team-owned shared infrastructure and workload-team-owned application resources, at a scale that fits a two-day event.

## What the platform lead needs

The built-in **Owner** role at Tenant Root scope (the script checks for the role named `Owner`, so an equivalent custom role doesn't pass). Tenant Root is the top management group of your Microsoft Entra tenant: every other management group and subscription sits under it, and a management group is a container that policy and access flow down from. Without this role, `Deploy-AlzLite.ps1` can't create management groups, move subscriptions into them or assign policies, and the deploy fails early with a clear permissions error.

In most tenants nobody has that role by default. A Global Administrator first elevates access (**Microsoft Entra ID** > **Properties** > **Access management for Azure resources**: set it to **Yes**), then gives the platform lead Owner at Tenant Root (in the portal: **Management groups** > **Tenant Root Group** > **Access control (IAM)** > **Add role assignment**). The script prints the exact `az role assignment create` command. Sign out and in again (`az logout`, then `az login`) before you re-run it.

## What the deploy creates

`Deploy-AlzLite.ps1` deploys at Tenant Root, against the shared services subscription. The platform lead runs it at T-7, before the event. Run it with `-WhatIf` first to see the changes without deploying. [C2](../../challenges/c02-secure-ai-ready-foundation/#before-the-event) has the commands.

- **Management groups:** `mg-factory` under Tenant Root, with `mg-factory-platform` (holds the shared services subscription) and `mg-factory-corp` (holds the members' workload subscriptions) beneath it. `-MgPrefix` changes the `mg-factory` prefix, so several kits can share a tenant.
- **`rg-management`:** the `log-management` workspace (30-day retention) and the identity `id-sqlmi-directory`.
- **`rg-hub`:** `vnet-hub`, `afw-hub` (Azure Firewall Standard) with its public IP and the `afwp-hub` policy (DNS proxy on), and the private DNS zones for Blob, Service Bus, the container registry and Key Vault, linked to the hub.
- **Defender for Cloud and policy:** Foundational CSPM only (cloud security posture management: recommendations, no paid protection plans), and the core policies at `mg-factory-corp` (summarized in the table below; the full list is in the [foundation README](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/infra/foundation/README.md)).

It takes 15 to 25 minutes, mostly Azure Firewall, and costs about $1.30 an hour while it exists. The firewall bills until `rg-hub` is deleted. A re-run converges. Policies can take up to 30 minutes to take effect.

:::caution[Defender for Cloud changes the whole subscription]

By default the deploy turns every paid Defender for Cloud plan off on the shared services subscription, including for resources the kit didn't create. Event subscriptions are dedicated, so that's what you want there. In a subscription that hosts other workloads, add `-SkipDefender` to leave the plans as they are.

:::

Vending then connects each member's workload subscription and datacenter to the hub. The platform lead runs it at T-1, after each member's `vm-dev01` setup and the coach's C0 review, because it changes the datacenter's DNS to the hub firewall. See [C2](../../challenges/c02-secure-ai-ready-foundation/#before-the-event) for the command and the [naming and IP plan](../../reference/naming-and-ip-plan/) for the addresses.

## One step that needs a directory role

ALZ-lite creates the identity `id-sqlmi-directory` in `rg-management`. Every member's SQL Managed Instance uses it, so `CREATE USER ... FROM EXTERNAL PROVIDER` can look up the web app's identity in C7. Once per team, right after `Deploy-AlzLite.ps1`, someone with the **Privileged Role Administrator** (or Global Administrator) Microsoft Entra directory role grants it Microsoft Graph read permissions (the three read-only application permissions that let SQL Managed Instance look up Entra users and apps) with `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId <shared-services-subscription-id>`. The platform lead usually doesn't hold that role, so it's a platform lead task done with a role holder: the event owner books that person for T-7, and they run it right after ALZ-lite. The role holder runs the script from their own computer, in the kit's `factory/` folder, signed in as themselves, not in the platform lead's signed-in terminal. The grant is tenant-wide and read-only, and members can attach the identity to other resources during the event, so the event owner agrees it with the tenant owner first, and they also arrange for the identity to be deleted afterward ([details](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/archetype/README.md#accepted-lab-risks-and-adopter-obligations)). [C2](../../challenges/c02-secure-ai-ready-foundation/#before-the-event) has the exact step, and the team checks the grant on day one.

## Fixed values

- Region: `swedencentral`, with `germanywestcentral` as the fallback if capacity is constrained.
- Hub address space: `10.100.0.0/16`.
- Azure Firewall: Standard SKU, DNS proxy enabled. No Premium features (TLS inspection, IDPS) — out of scope for a two-day event.
- Defender for Cloud: Foundational CSPM only (free). Paid Defender plans are off, on the whole shared services subscription. This is a deliberate AI-readiness gap, called out again in [C10](../../challenges/c10-package-hand-over-review-ai-readiness/)'s gap register, not an oversight to silently work around.
- No availability zones pinned, and no zone redundancy explicitly turned on anywhere in the kit. Where a service is zone-redundant automatically with no extra configuration (for example, Azure Container Registry or Azure Service Bus Premium), that's the platform's default behavior, not a kit setting — see the [availability zones reference](../../reference/availability-zones/).

## How it compares with a full ALZ

The coach's live demo in C2 shows a complete portal-deployed Azure Landing Zone. ALZ-lite deliberately narrows that scope for a two-day event:

| Full ALZ | ALZ-lite |
|---|---|
| Platform, Landing Zones, Sandbox and Decommissioned management groups | `mg-factory` (under Tenant Root) with `mg-factory-platform` and `mg-factory-corp` beneath it |
| Multiple landing zone archetypes (Corp, Online, confidential) | One archetype (Corp) |
| Full Azure Policy initiative set (hundreds of built-ins) | A small, fixed set: Audit for location, Deny for public network access/public IPs, DeployIfNotExists for private DNS and diagnostics (Audit only reports, Deny blocks the request, DeployIfNotExists adds the missing setting) |
| Defender for Cloud with paid plans | Foundational CSPM only, free |
| Hub with ExpressRoute/VPN gateways | Hub with Azure Firewall and no gateways: no ExpressRoute or VPN. The simulated datacenter peers with the hub instead, which stands in for the on-premises link |

None of these are mistakes in ALZ-lite — they're intentional simplifications for a lab, documented so you know what a real customer engagement would add back.
