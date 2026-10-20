# university — Handoff (Step 4 owner-reopened for kit #52/#60)

Updated: 2026-10-09 | IaC: Bicep | Current owner: 05-IaC Planner | Plan: DRAFT, gate-3 blocked by 569fbf8e

## Completed Steps

- [x] Step 1 → agent-output/university/01-requirements.md
- [x] Step 2 → agent-output/university/02-architecture-assessment.md
- [x] Step 3 → agent-output/university/03-des-adr-0001…0008 (8 ADRs) and 03-des diagrams, approved 2026-10-06
- [x] Step 3.5 → agent-output/university/04-governance-constraints.md
- [ ] Step 4 → revised draft for kit #52/#60; approval of predecessor plan `5a4b96e4` on 2026-10-07 is historical only
- [x] Step 5 → historical completion for plan `5a4b96e4`; validate/what-if and handoff tree hash `dcbe5478` do not cover this draft

## Key Decisions

- One subscription-scope deployment; inputs: tenant ID, subscription ID, suffix; region swedencentral (derived from hub)
- deployment_strategy=single; identity_model=user-assigned-shared (`id-university-<suffix>`, web app only); public_edge_auth=none
- script_runtime_image=not-applicable; az_posture=single-zone-mvp (forced values recorded: Service Bus `zoneRedundant`, ACR `zoneRedundancy`)
- 10 AVM modules, all MCR-latest and frozen; raw Bicep: SQL MI and `startStopSchedules` `@2025-01-01`, diagnostic settings `@2016-09-01`
- Stable APIs apply to archetype-declared resources; AVM-internal preview versions listed for B09 `versions.md`
- Hooks: pwsh 7; CLI plus authenticated ARM REST GET/PATCH to avoid Windows metacharacter handling; no infrastructure edited here
- SKU manifest rev 3 locked; 57f85f8d (deployer grant scope) and 569fbf8e (shared `id-sqlmi-directory` attachable outside SQL MI) are owner-accepted risks
- ACR `azureADAuthenticationAsArmPolicyStatus: 'enabled'` (UAMI pull); 3fd577cf deferred (policy 42781ec6 reports Audit or Disabled, never Deny)
- SQL MI identity `SystemAssigned,UserAssigned`, primary = `id-sqlmi-directory` (derived by preflight, no new member input)
- Subscription-ID exception covers all of `04-governance-constraints.json`; ADR-0008 keeps "about 20 minutes"

## Open Challenger Findings (must_fix only)

- Pass9 retains 569fbf8e as must-fix. Owner accepts hackathon-only residual LAB risk, not technical remediation.
	No supported APEX lab exception opens this gate; Step 4 stays DRAFT. See [risk record and owner route](README.md).

## Context for Next Step

- Owner approved Step 5 → Step 4 reopening only for kit #52/#60; `current_step=4`, `plan_status=DRAFT`, Step 4 in progress; no CodeGen, Azure operation or Step 6/7 completion authorized.
- #52/#60 inputs stay finalized and unchanged. Tenant-owner approval, event end, named cleanup owner and deletion proof remain outstanding; no final teardown is claimed. Human route: 01-Orchestrator for an authorized APEX lab-exception contract; acceptance alone grants no approval, completion or CodeGen.
- Draft adds component-scoped Monitoring Metrics Publisher for signed-in `deployerObjectId`; app UAMI role and `disableLocalAuth=true` retained. Four-script correction plans observed summaries and supported recall APIs, never hardcoded success or automatic advancement.
- All following Step 5 validation statements are historical (2026-10-07); they do not validate the revised plan or authorize deployment.
- Step 5 delta applied (contract `plan_ref` = `5a4b96e4`): ACR `azureADAuthenticationAsArmPolicyStatus: 'enabled'` with the post-deploy `authentication-as-arm` check; `sqlMiDirectoryIdentityId` param (`SQLMI_DIRECTORY_IDENTITY_ID`) feeding SQL MI `SystemAssigned,UserAssigned` and `primaryUserAssignedIdentityId`; preflight step 10 (identity exists, deployer can assign it) and the `atScope()` DINE query.
- Validation (2026-10-07, `workload`, suffix of the existing deployment because `snet-sqlmi` already hosts that MI): preflight passed, `bicep build`/`lint` clean, validate and what-if `Succeeded` (no resource Delete), `bicep-validate-subagent` APPROVED (L2 20 of 20), security baseline and SKU coverage pass. A provision run without `CONTAINER_IMAGE` previews the web app back on the MCR placeholder; deploy from an azd environment that has the registry copy. No tenant or subscription IDs are in the tree.
- Run the security scanner as `npm run validate:iac-security-baseline -- --public-web-app infra/bicep/university/modules/web-app.bicep`; without the flag the approved public web app is reported.
- Preflight step 9 reads inherited policy assignments through the ARM `atScope()` filter, because `az policy assignment list` omitted the management-group ALZ-lite assignments in this tenant.
- Azure Hybrid Benefit assumption and the opt-out are in `infra/bicep/university/README.md` (5d241bcc closed).
- Historical owner-approved variance: Key Vault `tenantId` input is not wired (AVM 0.14.2 has no such parameter). Child-heading warnings (`st-container`, `sbns-queue`, `sqlmi-schedule`) remain cosmetic; prior reviewed bytes are retained in historical evidence.
- Budget warning: `budget-factory-workload` is 500; the 24×7 run rate is about $1,321/month, so `actual80` will fire.
- Telemetry readiness stays pending the app image (B06/B10); local auth stays off.
- Owner-stated, not in Step 1–3.5 artifacts: MI link `vm-app01` → hub firewall → `snet-sqlmi`, TCP 5022 and 11000–11999 (B07/B08).
- B08 dependency (92079f7c, deferred): ALZ-lite creates `id-sqlmi-directory` and only teardown removes it; recovery is to re-run ALZ-lite, the grant script and vending. Verified 2026-10-07: it exists and the deployer can assign it.
- Before CodeGen, resolve wording referencing `metadata.plan_lock`: the graph owns static freeze policy, no runtime writer exists, and no runtime lock is fabricated. Renewed human gate-3 approval remains mandatory.

## Skill Context

- Guidance: [Azure defaults](../../.github/skills/apex-azure-defaults/SKILL.md), [Bicep patterns](../../.github/skills/apex-azure-bicep-patterns/SKILL.md), [CodeGen boundaries](../../.github/skills/apex-iac-common/references/codegen-do-dont.md)
- Security baseline: TLS 1.2, HTTPS-only, managed identity, no keys or secrets; AVM-first

## Artifacts

- [Plan](04-implementation-plan.md), [IaC contract](04-iac-contract.json), [policy map](04-policy-property-map.json), [environment manifest](04-environment-manifest.json)
- [Dependency](04-dependency-diagram.py), [runtime](04-runtime-diagram.py), [SKU manifest](sku-manifest.json).
- All historical reviews/dispositions and [pass 8](challenge-findings-plan-pass8.json) preserved; fresh unselected [pass 9](challenge-findings-plan-pass9.json) has 1 must-fix, no should-fix or suggestions, with strict primary/supporting hashes verified.
