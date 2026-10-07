---
description: "Deploy the CoE archetype (Contoso University platform) project with APEX Deploy and As-Built."
agent: "01-Orchestrator"
---

# Deploy the CoE archetype

Ask the user for three inputs, in order, if not already supplied in this conversation:

1. **Tenant ID** — the Entra tenant the workload subscription lives in.
2. **Subscription ID** — the workload subscription (already vended: it has `rg-spoke`
   with `vnet-spoke`, `snet-app`, `snet-pe` and `snet-sqlmi`).
3. **Suffix** — the member's 4–6 lowercase letters/digits suffix, unique per member.

## Prerequisites to check before deploying

- `az account show --query tenantId -o tsv` matches the supplied tenant ID. If not, run
  `az login --tenant <tenant-id>` and `az account set --subscription <subscription-id>`
  first, and stop to tell the user if sign-in fails.
- `az group show -g rg-spoke --subscription <subscription-id>` succeeds, and
  `az network vnet subnet list -g rg-spoke --vnet-name vnet-spoke --subscription <subscription-id>`
  includes `snet-app`, `snet-pe` and `snet-sqlmi`. If the spoke is missing, stop and tell
  the user to run `scripts/Deploy-Vending.ps1` from the kit repo first (B08) — this
  prompt never creates the spoke.
- `az account show --subscription <subscription-id> --query user.name -o tsv` is signed
  in interactively (not a service principal), because the SQL Managed Instance's Entra
  admin is the deploying user.

## Refresh governance before deploying

The packaged `agent-output/university/04-governance-constraints.json` and
`04-policy-property-map.json` carry the CoE build tenant's discovery, with
`discovery_status: "PARTIAL"` and `subscription_id: "unknown"` — deliberately stale, so
APEX's own L0-envelope staleness gate forces a refresh here, in the member's own
tenant, before anything deploys:

1. Hand off to **04g-Governance** to re-run live discovery against the supplied tenant
   ID and subscription ID. This overwrites `04-governance-constraints.{md,json}` with
   the member's real policy set.
2. Follow whatever APEX's own drift routing (`governance-drift-routing.md`) returns for
   the refreshed envelope:
   - If it only requires re-stamping `04-policy-property-map.json` (Step 4) and
     re-emitting `05-iac-handoff.json` (Step 5 / `06b-Bicep CodeGen`), let those steps
     run and continue.
   - If it demands a real change to `04-implementation-plan.md` or the Bicep in
     `infra/bicep/university/` — the member's policies genuinely differ from what this
     archetype assumes — **stop and tell the user**, same as any other Stop-and-ask.
     Don't continue to Deploy on a plan or Bicep that no longer matches what passed
     review.
3. Never hand-edit a hash or signature field (`l1m_ref.sha256`, `tree_hash`,
   `supporting_inputs`/`cache_inputs.artifact_sha` in any `challenge-findings-*.json`)
   to force a check to pass. Only the owning agent step may refresh those.

This refresh is part of this prompt, not a separate step the member runs: the contract
stays three inputs (tenant ID, subscription ID, suffix).

## Deploy

Once governance is refreshed and the prerequisites pass, hand off to **APEX Deploy**
(agent `07b-Bicep Deploy`, workflow step 6) against `infra/bicep/university/` with
`tenantId`, `subscriptionId` and `suffix` as inputs — let it run its own preflight and
what-if checks and ask for approval before it applies anything, same as any other APEX
deployment. After Deploy finishes, hand off to **As-Built** (agent `08-As-Built`,
workflow step 7) to generate `agent-output/university/07-as-built.md`.

Tell the user: this deploys the CoE archetype platform only (App Service, ACR, SQL MI,
Storage, Service Bus, Key Vault, Application Insights) into the existing spoke. It does
not deploy or modernize the Contoso University app itself (that's a separate
modernization workstream, B06/B10/C6), and the SQL MI takes several minutes to
provision in the background after the rest of the platform is ready.
