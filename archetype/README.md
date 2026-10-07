# The CoE archetype: Contoso University platform

> **Status: packaged, not yet deployed.** `agent-output/university/` and `infra/bicep/university/`
> are the owner's real APEX output (requirement 9), copied in at requirement 11 with the two
> governance files redacted as described below. Requirements 16-20 (deploy, validate, tear down)
> are still pending; the Validation record table below fills in once those run.

## What this is

An [APEX](https://github.com/jonathan-vella/apex-accelerator) project that designs and deploys the
private-by-default Azure platform for the modernized Contoso University web app: App Service, a
container registry, a SQL Managed Instance, Blob storage, Service Bus, Key Vault and Application
Insights, in a Corp landing zone spoke that already exists (B08). It does not deploy or modernize
the app itself -- that is the separate app- and database-modernization work (B06, B10, B11).

APEX release/commit this project is pinned to: `apex-accelerator` has no tagged releases as of
2026-10-05, so this records the commit SHA the owner's APEX session actually used. `BRIEF.md`'s
Notes section names `bc96b7284eb116ab5c2ee71b9ba9510f4c22d99a` as the commit current at
brief-authoring time, but the owner's `apex-factory-coe` repo was synced to upstream APEX
`c209d8b` before running steps 1-5 -- `c209d8b` is the commit actually pinned, not `bc96b72`.

**App Service plan `P0v3` VNet integration:** confirmed supported (regional VNet integration is a
Premium-tier App Service Plan feature, and P0v3 is a Premium v3 SKU); the Bicep wires
`virtualNetworkSubnetResourceId` into `snet-app` accordingly.

## Layout

```text
archetype/
  BRIEF.md                           the brief pasted into APEX step 1 (requirement 1)
  README.md                          this file
  deploy.ps1                         no-agent fallback deploy (requirement 14)
  .github/prompts/
    deploy-archetype.prompt.md       prompt that drives APEX Deploy + As-Built (requirement 13)
  agent-output/university/           APEX's artifacts (92 files), copied in with 04-governance-
                                      constraints.json and 04-policy-property-map.json redacted
  infra/bicep/university/            APEX's generated Bicep, copied in as-is (main.bicep,
                                      main.bicepparam, azure.yaml, modules/, scripts/)
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
name, and the SQL MI Entra admin from the signed-in user. It runs a plain `az deployment sub
create` of `infra/bicep/university/main.bicep` (subscription-scope; the template creates its own
`rg-university-<suffix>`).

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

## Governance files and APEX's hash chain

`agent-output/university/04-governance-constraints.json` and `04-policy-property-map.json` are
packaged with every build-tenant identifier redacted: the workload subscription's `subscription_id`
field (2 occurrences), the tenant-root management-group ID (335 + 9 occurrences across the two
files), and the **shared services subscription ID** embedded in `/subscriptions/<id>/...` resource
paths for the hub's private DNS zones and `log-management` (22 occurrences, `04-governance-
constraints.json` only) -- and `discovery_status: "PARTIAL"` set, not because the CoE build
tenant's policies don't apply, but because they're specific to that tenant and wouldn't exist in a
member's. `04-policy-property-map.json`'s `constraints_ref.sha256` (an internal cross-reference
between the two packaged files) is recomputed against the redacted `04-governance-constraints
.json`, so that check still passes.

This redaction, verified against this package with the real validators:

- `validate-policy-property-map.mjs`: **passes** (22 policies, `constraints_ref` recomputed).
- `validate-governance-refs.mjs`: **passes**, unaffected.
- `validate-governance-trace.mjs --through L3`: the L0 gate **fails on `discovery_status: PARTIAL`
  by design** -- this is exactly the mechanism that forces `deploy-archetype` to re-run live
  discovery in the member's tenant before Deploy. The L1 matrix (20 rows) still passes: redaction
  doesn't corrupt the policy-compliance content, only the subscription/tenant identifiers.
- `validate-iac-handoff.mjs` (no `--skip-tree-hash`): **one error**,
  `governance_attestation.l1m_ref.sha256` mismatch (it hashes the now-redacted
  `04-policy-property-map.json`). `tree_hash` over `infra/bicep/university/` is untouched by
  redaction and passes.
- `validate-challenger-findings.mjs --verify-cache`: **already fails on the unmodified source**
  (41 errors, intermediate `-pass*`/base sidecar files going stale as later passes revised the
  underlying documents -- normal APEX multi-pass history, not a redaction effect). Redaction adds
  12 more `supporting bytes changed` errors, for intermediate sidecars whose `supporting_inputs`
  hash the two governance files. The sidecars that actually matter -- the final `-decisions.json`
  files -- carry no `cache_inputs`/`supporting_inputs` hash fields at all, so none of them are
  affected either way.

There is no sanctioned way to refresh `l1m_ref` or the sidecar hashes without re-running the owning
APEX step (Step 6 re-emits `05-iac-handoff.json`; a fresh Step 3.5 Challenger pass refreshes a
sidecar), and this kit never hand-edits a hash to force a check to pass. They document the CoE
build tenant's own review history; a member's `deploy-archetype` run re-discovers governance and
re-emits its own `05-iac-handoff.json` before Deploy, which is what actually matters for their
deployment. See the PR for the exact command output.

### ID scan

Before every commit touching `archetype/`, grep it for the tenant ID, the workload and shared
services subscription IDs (`.local/settings.json`) and the signed-in deployer's object ID; expect
zero hits. Built-in Azure policy/role definition GUIDs (public, not tenant-specific) are expected
and fine.

### Run APEX in the dev container, not natively on Windows

APEX's `.gitattributes` forces LF for `*.bicep` but not for `*.bicepparam`; with `* text=auto`, a
native Windows git checkout turns `main.bicepparam`'s line endings to CRLF, which changes its hash
and breaks `tree_hash` (declared vs actual mismatch). This kit's own `.gitattributes`
(`* text=auto eol=lf`) keeps the committed `archetype/` bytes LF, but a member who then clones
*their* APEX repo natively on Windows can reintroduce the problem. Run APEX (and `apex-recall`) in
the dev container or GitHub Codespaces, not natively on Windows; if you must clone on Windows for
some other reason, use `git -c core.autocrlf=false -c core.eol=lf clone ...` and verify `tree_hash`
before relying on it. Follow-up filed upstream: `apex-accelerator`'s `.gitattributes` should add
`*.bicepparam text eol=lf`.

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
