---
title: ALZ-lite
description: The two-subscription model, what the deploy creates, what's fixed, and how it compares with a full ALZ.
sidebar:
  order: 4
---

This guide covers the mechanics of the kit's landing zone. [C2](../../challenges/c02-secure-ai-ready-foundation/) is the what, the stages the team lead runs before the event, and the acceptance bar for the day-one walk-through. The commands are in [Team lead steps](../../deploy/team-lead-steps/).

## The two-subscription model

Each team uses two kinds of subscription:

- **One shared services subscription**, held by the team lead. It hosts the hub, the management group hierarchy, central policies and the central Log Analytics workspace.
- **One workload subscription per member**, vended into the hierarchy as a spoke with its own subnets, peering back to the hub, and member-scoped budgets and RBAC. (Vending is connecting a subscription to the hub: spoke network, peering, DNS, firewall rules, budget. The hub is the shared virtual network; a spoke is a member's network that peers with it.)

This mirrors the real distinction between platform-team-owned shared infrastructure and workload-team-owned application resources, at a scale that fits a two-day event.

## What the team lead needs

The built-in **Owner** role at Tenant Root scope (the pipeline's preflight checks for the role named `Owner`, so an equivalent custom role doesn't pass). Tenant Root is the top management group of your Microsoft Entra tenant: every other management group and subscription sits under it, and a management group is a container that policy and access flow down from. Without this role, the `foundation` stage can't create management groups, move subscriptions into them or assign policies, and the run fails early with a clear permissions error.

In most tenants nobody has that role by default. A Global Administrator first elevates access (**Microsoft Entra ID** > **Properties** > **Access management for Azure resources**: set it to **Yes**), then gives the team lead Owner at Tenant Root (in the portal: **Management groups** > **Tenant Root Group** > **Access control (IAM)** > **Add role assignment**). The preflight prints the exact `az role assignment create` command. Sign out and in again (`az logout`, then `az login`) before you run the stage again.

## What the deploy creates

The team lead deploys ALZ-lite with the `foundation` stage at T-7, before the event, against the shared services subscription. The `whatif` stage shows the changes first without deploying. [Team lead steps](../../deploy/team-lead-steps/#t-7-foundation) has the steps.

- **Management groups:** `mg-factory` under Tenant Root, with `mg-factory-platform` (holds the shared services subscription) and `mg-factory-corp` (holds the members' workload subscriptions) beneath it.
- **`rg-management`:** the `log-management` workspace (30-day retention) and the identity `id-sqlmi-directory`.
- **`rg-hub`:** `vnet-hub`, `afw-hub` (Azure Firewall Standard) with its public IP and the `afwp-hub` policy (DNS proxy on), and the private DNS zones for Blob, Service Bus, the container registry and Key Vault, linked to the hub.
- **Defender for Cloud and policy:** Foundational CSPM only (cloud security posture management: recommendations, no paid protection plans), and the core policies at `mg-factory-corp` (summarized in the table below; the full list is in the [foundation README](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/infra/foundation/README.md)).

It takes 15 to 25 minutes, mostly Azure Firewall, and costs about $1.30 an hour while it exists. The firewall bills until `rg-hub` is deleted. A re-run converges. Policies can take up to 30 minutes to take effect.

:::note[Defender for Cloud changes the whole subscription]

By default the deploy turns every paid Defender for Cloud plan off on the shared services subscription, including for resources the kit didn't create. Event subscriptions are dedicated, so that's what you want there. Never run the foundation in a subscription that hosts other workloads.

:::

Vending then connects each member's workload subscription and datacenter to the hub. The team lead runs it at T-1, after each member's `vm-dev01` setup and the coach's approval of the readiness record, because it changes the datacenter's DNS to the hub firewall. See [Team lead steps](../../deploy/team-lead-steps/#t-1-vending) for the steps and the [naming and IP plan](../../reference/naming-and-ip-plan/) for the addresses.

<figure class="doc-figure">
  <a class="doc-figure__link" href="/diagrams/diagram-04-hub-and-spoke-routing.svg" target="_blank" rel="noopener">
    <img src="/diagrams/diagram-04-hub-and-spoke-routing.svg" alt="Traffic between a member's datacenter and spoke crosses the hub firewall. The shared hub holds Azure Firewall. Each member has a datacenter network with vm-app01 and vm-dev01 and a spoke network with subnets for the app, private endpoints and SQL Managed Instance. Route tables send datacenter-to-spoke traffic and the spoke's outbound traffic to the firewall, and the datacenter's internet traffic leaves through a NAT Gateway." width="3840" height="2160" loading="lazy" decoding="async" />
  </a>
  <figcaption>What vending connects: routes through the hub firewall. <a href="/diagrams/diagram-04-hub-and-spoke-routing.svg" target="_blank" rel="noopener">Open full size</a></figcaption>
</figure>

## One step that needs a directory role

ALZ-lite creates the identity `id-sqlmi-directory` in `rg-management`. Every member's SQL Managed Instance uses it, so `CREATE USER ... FROM EXTERNAL PROVIDER` can look up the web app's identity in C7. Once per team, right after the `foundation` stage, someone with the **Privileged Role Administrator** (or Global Administrator) Microsoft Entra directory role grants it Microsoft Graph read permissions (the three read-only application permissions that let SQL Managed Instance look up Entra users and apps) with `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId <shared-services-subscription-id>`. The team lead usually doesn't hold that role, so it's a team lead task done with a role holder: the team lead arranges that person for T-7 (a coach can help), and they run it right after ALZ-lite. The role holder runs the script from their own computer, signed in as themselves, not in the team lead's signed-in terminal. They don't need the lead's repo: the script is one file with no other kit dependencies, so they download [`Grant-SqlMiDirectoryRead.ps1`](https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/scripts/Grant-SqlMiDirectoryRead.ps1), install PowerShell 7 and the Azure CLI, and need Reader on the shared services subscription. The grant is tenant-wide and read-only, and members can attach the identity to other resources during the event, so the team lead agrees it with the tenant owner first and arranges for the identity to be deleted afterward ([details](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/archetype/README.md#accepted-lab-risks-and-adopter-obligations)). [Team lead steps](../../deploy/team-lead-steps/#graph-grant) has the exact step, and the team checks the grant on day one.

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
