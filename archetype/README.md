# The CoE archetype: Contoso University platform

> **Status: packaging in progress.** This README is a first-pass skeleton written before APEX's
> output exists. It will be finalized against the actual APEX project and Bicep once the owner's
> APEX session (requirement 9) completes and the project is packaged into this folder
> (requirement 11). Anything marked `TODO (post-APEX)` below needs that pass.

## What this is

An [APEX](https://github.com/jonathan-vella/apex-accelerator) project that designs and deploys the
private-by-default Azure platform for the modernized Contoso University web app: App Service, a
container registry, a SQL Managed Instance, Blob storage, Service Bus, Key Vault and Application
Insights, in a Corp landing zone spoke that already exists (B08). It does not deploy or modernize
the app itself -- that is the separate app- and database-modernization work (B06, B10, B11).

APEX release/commit this project is pinned to: `TODO (post-APEX)` -- `apex-accelerator` has no
tagged releases as of 2026-10-05, so this records the commit SHA the owner's APEX session used
instead of a release tag (see `BRIEF.md`'s Notes section for the pinned commit at brief-authoring
time: `bc96b7284eb116ab5c2ee71b9ba9510f4c22d99a`).

## Layout

```text
archetype/
  BRIEF.md                           the brief pasted into APEX step 1 (requirement 1)
  README.md                          this file
  deploy.ps1                         no-agent fallback deploy (requirement 14)
  .github/prompts/
    deploy-archetype.prompt.md       prompt that drives APEX Deploy + As-Built (requirement 13)
  agent-output/university/           TODO (post-APEX): APEX's artifacts, copied in as-is
  infra/bicep/university/            TODO (post-APEX): APEX's generated Bicep, copied in as-is
```

This mirrors APEX's own repo layout (`agent-output/{project}/`, `infra/bicep/{project}/`), so a
member can copy the contents of `archetype/` straight into the matching paths of their own APEX
repo and continue from there.

## Deploy it

### With APEX (recommended)

1. Create a repo from the [`apex-accelerator`](https://github.com/jonathan-vella/apex-accelerator)
   template, at the commit this project is pinned to (above).
2. Copy this folder's `agent-output/university/`, `infra/bicep/university/` and
   `.github/prompts/deploy-archetype.prompt.md` into the matching paths of that repo.
3. Run the `deploy-archetype` prompt. It asks for tenant ID, subscription ID and suffix, checks
   that a spoke is already vended, then hands off to **APEX Deploy** (agent `07b-Bicep Deploy`,
   workflow step 6) and **As-Built** (agent `08-As-Built`, workflow step 7).
4. Verify with APEX's `apex-recall` (or its current equivalent) that workflow state shows steps 1-7
   complete.

### Fallback (no agent)

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix
```

`deploy.ps1` takes the same three inputs and discovers everything else the same way APEX does: the
hub from the spoke's peering, the region from the hub, the Log Analytics workspace by its ALZ-lite
name, and the SQL MI Entra admin from the signed-in user. It runs a plain `az deployment group
create` of `infra/bicep/university/main.bicep`.

## Inputs

Only three: **tenant ID**, **subscription ID**, **suffix**. Everything else -- region, spoke,
subnets, Log Analytics workspace, SQL MI Entra admin -- is derived or discovered by both the APEX
path and the fallback script, by the backlog's naming conventions.

## Cost

About **$4.63/hour** while deployed: SQL MI General Purpose 4 vCores with AHB about $0.68, Service
Bus Premium about $0.93, App Service P0v3 about $0.10, ACR Premium about $0.07, private endpoints
about $0.05 (plus the foundation it runs on: ALZ-lite about $1.25 and the datacenter about $1.55).
The SQL MI can't be stopped while an MI link is active (B07).

## Public-endpoint exceptions

The archetype is private-only apart from two documented public endpoints, both required for the
app to function:

1. **The web app's front end** -- the only public inbound endpoint; it's the point of the exercise.
2. **Application Insights ingestion** -- stays public; there is no private-endpoint-only ingestion
   path for the workspace-based resource this kit uses.

Separately, the container registry allows **trusted Azure services** to bypass its network rules
(while `publicNetworkAccess` stays off and no other public access is granted), so `az acr import`
of the known-good image works in B10. This is a deliberate, documented exception to "private
backends," not a public endpoint -- it does not open the registry to the internet.

## Azure Hybrid Benefit

SQL MI deploys with `licenseType: 'BasePrice'`, which assumes the subscription has Software
Assurance-eligible SQL Server core licenses to cover it (Azure Hybrid Benefit). This is the kit-wide
default (see `docs/backlog/README.md`). To turn AHB off and pay full license-included pricing
instead, change `licenseType` to `'LicenseIncludedPrice'` in `infra/bicep/university/main.bicep`
(or override it as a deployment parameter) before deploying.

## Validation record

| Path | Time to ready (excl. MI) | MI provisioning time | Notes |
|---|---|---|---|
| APEX Deploy + As-Built | `TODO (post-deploy)` | `TODO (post-deploy)` | requirement 18, fresh repo |
| `deploy.ps1` fallback | `TODO (post-deploy)` | `TODO (post-deploy)` | requirement 17 |

Requirement-19 checks (public-endpoint audit, policy compliance, private DNS resolution, image
push/pull/restart, telemetry reaching Application Insights): `TODO (post-deploy)`.
