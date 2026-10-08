# B09: Build the CoE archetype with APEX

| Field | Value |
|---|---|
| Milestone | P3 Build |
| Type | Both |
| Depends on | B06, B07, B08 |
| Unblocks | B10, B11 |
| Effort | 3–4 days elapsed, including the owner's APEX session |
| Cost | The archetype adds about $1.83/hour while deployed: SQL MI General Purpose 4 vCores with AHB about $0.68, Service Bus Premium about $0.93, App Service P0v3 about $0.10, ACR Premium about $0.07, private endpoints about $0.05. The foundation it runs on (ALZ-lite about $1.30, the datacenter about $1.55) is about $2.85/hour on its own, so the kit total with both deployed is about $4.63–$4.66/hour |
| Teardown | Delete everything this item created: the archetype resources, `rg-spoke` and `rg-datacenter` in the workload subscription, `rg-hub` and `rg-management` in the shared services subscription, the policy assignments and budget, and the kit's management groups after moving both subscriptions back to their original place |
| PRD | §2 Archetype, Compute, Messaging, Hybrid Benefit; §5 C5; §6 CoE archetype |

## Outcome

- `archetype/` holds the CoE archetype: an APEX project with steps 1–5 complete (artifacts, challenger reviews and workflow state) and the Bicep it produced, pinned to an APEX release.
- A member deploys it with APEX Deploy and As-Built, supplying only tenant ID, subscription ID and suffix. A plain `az deployment` script is the no-agent fallback.
- It deploys into a vended spoke, with private-only backends, policy-compliant under ALZ-lite: App Service for Linux (the web front end, public inbound), ACR Premium, SQL MI General Purpose, Blob storage, Service Bus Premium, Key Vault and Application Insights, with the identities and roles the modernized app needs.

## Before you start

1. B06, B07 and B08 are closed. Read the B06 and B07 reports' recommendations for B09.
2. The workload subscription has SQL MI vCore quota for a 4-vCore General Purpose instance in the region.
3. `.local/settings.json` has `tenantId`, `subscriptionId`, `location`, `memberIndex` and `suffix`.

## Requirements

### Brief for APEX

1. `archetype/BRIEF.md` is the input the owner gives APEX step 1. It states the requirements below as a workload brief, in APEX's terms, so that APEX's own agents make the architecture and code. It names the APEX release to use: the latest `apex-accelerator` release on the day, recorded in the brief.
2. The workload: hosting for a modernized .NET 10 web app (Contoso University) in a Corp landing zone spoke that already exists, with private-only backends and a public web front end, with these services:

   | Service | Requirements |
   |---|---|
   | App Service plan and web app | Linux, container, SKU P0v3, one instance, zone redundancy off (🔎 VERIFY P0v3 supports VNet integration); VNet integration in `snet-app` with all traffic routed through the VNet and image pull over the VNet; **public inbound on** (the web front end is the only public endpoint), no private endpoint; HTTPS only; TLS 1.2 minimum |
   | Container registry | Premium; private endpoint; public network access off; admin user off; no zone setting (zone-redundant automatically, backlog conventions); **trusted Azure services allowed**, so `az acr import` of the known-good image works (B10). Document this as a deliberate exception |
   | SQL Managed Instance | General Purpose (paid, never the free offer), 4 vCores, Standard-series (Gen5) hardware, 64 GB storage, zone redundancy off; in `snet-sqlmi`; reached on its VNet-local endpoint (no private endpoint); database format SQL Server 2022; Entra-only authentication with the deploying user as admin; public endpoint off; a stop and start schedule for the event hours, noting it only applies after cutover; `licenseType: 'BasePrice'` (AHB) |
   | Storage account | Standard general-purpose v2, LRS; Blob container `teaching-materials`; private endpoint; public network access off; shared key access off |
   | Service Bus | Premium, 1 messaging unit; queue `notifications`; private endpoint; public network access off; local auth off; no zone setting (zone-redundant automatically, backlog conventions) |
   | Key Vault | RBAC authorization; private endpoint; public network access off; soft delete on, purge protection off |
   | Application Insights | Workspace-based, on the central Log Analytics workspace. Ingestion stays public: the documented private-only exception (backlog conventions) |
   | Managed identity | One user-assigned identity for the web app, so roles exist before the first image pull |

3. Roles: the web app's identity gets AcrPull, Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, and Key Vault Secrets User. The deploying member gets AcrPush, Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, and Key Vault Secrets Officer, for local runs from the dev VM.
4. App settings the modernized app reads, named as the B06 report recommends: the Blob endpoint, the Service Bus namespace and queue, the Key Vault URI, the identity's client ID and the Application Insights connection string. No secrets in app settings. The SQL MI connection (host and database, for managed identity) is not an app setting: per the B06 report, it lives in the Key Vault secret `ConnectionStrings--DefaultConnection`, which C7 (after cutover) writes with the Entra-only MI connection string and a contained user.
5. **Inputs:** only tenant ID, subscription ID and suffix. Everything else is derived or discovered: the hub (in the team's shared services subscription) from `vnet-spoke`'s peering, the region from the hub, the spoke and subnets by the backlog naming conventions, the Log Analytics workspace by its ALZ-lite name in the shared services subscription, and the MI Entra admin from the signed-in user. Resource names follow the conventions: CAF abbreviation + `university` + suffix.
6. **Private DNS:** the archetype doesn't create DNS zones or zone groups. The landing zone's DeployIfNotExists policy registers private endpoints in the central zones (ALZ-lite, B08), which live in the shared services subscription. SQL MI has no private endpoint: the app uses its VNet-local host name, which resolves to its private IP.
7. **Constraints** (APEX security baseline): no public endpoints apart from the two documented exceptions (the web app's front end and Application Insights ingestion -- the container registry's trusted-Azure-services bypass is a network-rule exception, not a public endpoint: `publicNetworkAccess` stays off), diagnostics to the central workspace, managed identity everywhere, Entra-only SQL, no availability zones pinned and no zone redundancy turned on (backlog conventions), and every deny policy in ALZ-lite passes.
8. **Initial image:** the web app starts with a placeholder image from Microsoft Container Registry, which vending's firewall rules allow (B08), until the member pushes the real image in C6.

### APEX session

9. 🧑 HUMAN: the owner runs APEX steps 1–5 from their own device, in their own repo created from `apex-accelerator`, using `archetype/BRIEF.md`. They pass every human gate and challenger review, then tell the executor the repo and commit.
10. Review APEX's output against requirements 2–8 and list any gap in a table in the PR body. If a gap needs another APEX pass, 🧑 HUMAN: the owner re-runs the step, and you review again.

### Package

11. Copy the APEX project for the archetype (its artifacts, challenger sidecars, workflow state and Bicep) from the owner's repo at that commit into `archetype/`, keeping APEX's folder layout so it works when a member copies it into their own APEX repo. Don't copy anything unrelated to this project.
12. `archetype/README.md`: what the archetype is, which APEX release it's pinned to, how a member imports it into their APEX repo (owner-approved addition, 2026-10-08: `archetype/Import-Archetype.ps1`, a one-command import — `-Ref` pinned to a kit tag/commit, no `main` default; `-Destination` their repo root; `-Force` to overwrite; downloads `archetype/` via the GitHub tarball API, no git clone, no auth; copies `agent-output/university/`, `infra/bicep/university/` and `.github/prompts/adapt-archetype.prompt.md`; refuses an existing `university` project unless `-Force`; adds the prompt to `EXCLUDE_PATHS` in the destination's `weekly-upstream-sync.yml` idempotently, because `.github/prompts/` is otherwise synced wholesale from upstream and would lose the prompt on the next sync; reports a file count and content hash for `infra/bicep/university/` as a byte check, not asserted against the packaged tree hash — a mismatch there is the already-recorded drift, not something the script resolves) and deploys it (owner decision, 2026-10-07: **`azd` is the primary deploy path** — `azd provision` from `archetype/infra/bicep/university/`; APEX Deploy, agent `07b`, workflow step 6, stays an optional advanced path; `archetype/deploy.ps1` stays the no-azd fallback), the inputs, the cost per hour, the two private-only exceptions, and an **Azure Hybrid Benefit** section for SQL MI (what's on, how to turn it off). 🔎 VERIFY the agent IDs and step numbers against the pinned APEX release, and use that release's IDs everywhere.
13. A prompt file, placed where APEX loads prompts, named `adapt-archetype` (owner decision, 2026-10-07 — renamed from `deploy-archetype` per the PRD): an **adapt** prompt — runs in VS Code's **built-in agent mode** (owner decision, 2026-10-08 — not `01-Orchestrator`, which would route on to APEX Deploy/`07b`) and is **self-contained**: it asks for tenant ID, subscription ID and suffix, checks the prerequisites (vended spoke exists, signed in to the right subscription), runs a **lightweight governance check** (owner decision, 2026-10-08 — live Deny-effect discovery against the member's subscription written only to a gitignored `agent-output/university/tmp/`, diffed against the packaged `04-governance-constraints.json`/`04-policy-property-map.json` by policy definition and resource type; stops only on a genuinely new deny for a resource type this archetype deploys; never overwrites the tracked `04-governance-*` files and never runs APEX's drift routing or a Step 4/5 re-emission), creates the `azd` environment and sets the three inputs, sets `AZURE_LOCATION` from the hub's region (a core azd value azd requires before it will provision at all on a fresh environment, derived the same way `preflight.ps1` does, via the spoke's peering), then runs `./scripts/preflight.ps1` in the same shell session — required for the remaining derived values, because `azd provision --preview` compiles `main.bicepparam`'s `readEnvironmentVariable()` calls before the `preprovision` hook would otherwise derive them, failing with `BCP427` on a fresh environment otherwise — and ends at `azd provision --preview`, explaining it to the member, including that the preview only lists resource types azd has display names for (it omits the SQL MI, UAMI, role assignments, diagnostic settings and the schedule, which are still created). It never runs `azd provision`, `azd down`, `07b-Bicep Deploy`, or anything else that writes to Azure.
14. `archetype/deploy.ps1` (attendee script conventions): the no-agent fallback. It takes the same three inputs, discovers the rest the same way, and runs a plain `az deployment` of the archetype's Bicep. It prints the cost and that the MI provisions in the background.
15. `archetype/` must work in a member's APEX repo: 🔎 VERIFY with APEX's `apex-recall` (or its current equivalent) that the workflow state shows steps 1–5 complete and the Deploy step (agent `07b`) next.

### Validate for real

16. Deploy ALZ-lite (shared services subscription), then the datacenter and vending (member 1, workload subscription) with the kit scripts.
17. Deploy the archetype with `archetype/deploy.ps1`. Record the time until everything except the MI is ready, and the MI provisioning time.
18. 🧑 HUMAN: the owner imports `archetype/` into a fresh APEX repo (with `archetype/Import-Archetype.ps1`, requirement 12) and runs the `adapt-archetype` **adapt** prompt in VS Code's built-in agent mode against a clean spoke (delete the archetype resources first), then `azd provision`, then As-Built (agent `08`) (owner decision, 2026-10-07: azd replaces APEX Deploy/07b as the deployment step; As-Built still runs after; owner decision, 2026-10-08: the prompt runs standalone, not via `01-Orchestrator`, and does a lightweight governance check rather than a full refresh + drift routing). This proves the member path end to end: the lightweight governance check (live Deny-effect discovery, diffed against the packaged policy set), then the prompt's `azd env new` + `preflight.ps1` + `azd provision --preview`, the member's own `azd provision`, and As-Built. Record the time for each step, the total, and any gaps, against C5's 1-hour box (PRD §6). If the governance check finds a genuinely new deny on a resource type this archetype deploys, or the chain can't finish, stop and report: the archetype's plan and Bicep no longer match what passed review in the member's tenant. `archetype/deploy.ps1` stays the dependable fallback either way. **Findings from this run:** on a fresh azd environment, `azd provision --preview` fails with `BCP427` (missing `LOG_ANALYTICS_WORKSPACE_ID`, `SQLMI_DIRECTORY_IDENTITY_ID`, `DEPLOYER_OBJECT_ID`, `DEPLOYER_UPN`, `AZURE_LOCATION`) because the Bicep param file compiles before the `preprovision` hook that derives them runs — fixed in packaging by having the prompt/README run `preflight.ps1` explicitly, in the same shell, right before the preview (not an azd or Bicep defect, and not something the hook itself needed to change). `AZURE_LOCATION` additionally needs to be set with `azd env set` *before* `preflight.ps1` runs: it's a core azd environment value azd requires on a fresh environment before it will provision at all, independent of `main.bicepparam`'s own read of it, so the prompt/README derive it from the hub's region (same peering lookup `preflight.ps1` uses) and set it first. `azd provision --preview`'s own output only lists resource types azd has display names for — this run showed 12 creates and omitted the SQL MI, the UAMI, role assignments, diagnostic settings and the maintenance schedule, though all are in the template and were created on `azd provision`; documented so members don't read the preview as missing the MI. `azd` stores the tenant/subscription IDs it's given in the gitignored `.azure/<env>/.env` — expected, not a leak. Governance-check result: the packaged policy set matched the member tenant exactly (65 policies, same signature) — no new denies found, confirming the tmp-only design needs no further changes. **`azd provision` outcome (read-only verification, 2026-10-08):** deployment `m18f06-1791436413` (subscription scope, branch `member-test-azd` @ `4bac6e0`) started 05:13:45 UTC and reported `Succeeded` (22m59s) on the next 10-minute poll. `rg-university-m18f06` has all 17 expected resources (SQL MI, UAMI, App Insights, storage, Service Bus, ACR, Key Vault, 4 private endpoints + NICs, App Service plan, web app). The MI's `primaryUserAssignedIdentityId` is `id-sqlmi-directory` in `rg-management`. ACR `authentication-as-arm` is `enabled`. The web app has `httpsOnly=true`, `minTlsVersion=1.2`, `ftpsState=Disabled`, and answers `https://app-university-m18f06.azurewebsites.net` with HTTP 200. Private DNS A records exist in all four `privatelink.*` zones for the `m18f06` resources. `az policy state summarize` on the resource group shows zero non-compliant Deny-effect (ALZ-lite `alzl-deny-*`/`alzl-allowed-locations`/`alzl-location-match-rg`) assignments; the only non-compliance is the already-documented `alzl-diag-appinsights` DINE compliance-reporting gap (confirmed: no diagnostic setting yet on `appi-university-m18f06` — a DeployIfNotExists policy awaiting its remediation task, not a Deny, and the same gap recorded for the earlier `deploy.ps1` run) plus unrelated Audit/AuditIfNotExists findings under `azure_security_baseline`/`mcapsgovauditpolicies`. This was read-only verification only; the owner's `postprovision` hook output and As-Built run live in the owner's own terminal and were not re-run.
19. Check: no public endpoints beyond the two documented exceptions (every backend resource's public network access is off; no public IPs outside the hub and the datacenter's NAT gateway and Bastion); zero non-compliant resources for the ALZ-lite policies in the archetype's resource group after evaluation (`alzl-allowed-locations` and `alzl-location-match-rg` are Audit, not Deny -- check zero non-compliant there too, not a blocking gate); private endpoints registered in the central zones; the MI host name resolves to its private IP from `vm-dev01`; `scripts/Test-Connectivity.ps1` passes, including the private endpoint checks; from `vm-dev01`, push a test image to the registry and restart the web app with it; the web app pulls it with its identity and answers on its public HTTPS endpoint; the web app's telemetry reaches Application Insights.
20. Tear everything down (Teardown row), including the subscription-level artifacts listed in the backlog conventions, and query each to confirm.

### Records

21. `versions.md`: the APEX release, the API versions APEX pinned for each service, and the MI database format, validated today.

## Deliverables

- `archetype/BRIEF.md`, `archetype/README.md`, `archetype/deploy.ps1`, the `adapt-archetype` prompt, and the APEX project output (artifacts, sidecars, workflow state, Bicep).
- `versions.md` updated.

## Verify

```powershell
Get-ChildItem archetype -Recurse -Filter *.bicep | ForEach-Object { az bicep lint --file $_.FullName }
Invoke-ScriptAnalyzer -Path archetype/deploy.ps1
npm run check

# ID scan: expect 0 hits (built-in policy/role definition GUIDs are fine)
$s = Get-Content .local/settings.json | ConvertFrom-Json
$deployerObjectId = (az ad signed-in-user show --query id -o tsv)
foreach ($id in @($s.tenantId, $s.subscriptionId, $s.sharedSubscriptionId, $deployerObjectId)) {
    Get-ChildItem archetype -Recurse -File | Select-String -Pattern $id
}
```

- Lint and PSScriptAnalyzer are clean.
- The ID scan finds zero hits.
- The PR body has the gap table, both deployment times, the checks from requirement 19 and the cost.

## Done when

- [x] `archetype/` holds a complete APEX project, pinned and documented.
- [ ] The archetype deploys from only tenant ID, subscription ID and suffix, both through APEX and through the fallback. **Pending (requirement 18):** `deploy.ps1` and `azd provision` both validated end to end from `.local/settings.json` inputs only; the owner's interactive `adapt-archetype` adapt-prompt run is scheduled next.
- [x] Every check in requirement 19 passes (two documented non-blocking gaps: the `alzl-diag-appinsights` DINE compliance-reporting gap, and the SQL MI port-11000 structural false negative — both recorded in the PR).
- [ ] Everything is torn down. **Pending (requirement 20):** the archetype resource group is deleted and the Key Vault purged; the foundation (ALZ-lite, datacenter, vending, `id-sqlmi-directory`) is kept running overnight by owner decision for the requirement 18 run.

## Commit message

```text
feat: add the CoE archetype built with APEX
```

## Stop and ask if

- APEX's output differs from the brief in a way that changes cost, security or the app's contract.
- A deny policy blocks the archetype.
- The MI fails to provision, or the subscription's SQL MI vCore quota is too small.

## Notes and traps

- **Markdown:** `archetype/` is excluded from the repo's Markdown lint (B01), because it's APEX output.
- **Role propagation:** role assignments can take minutes to apply. The first image pull can fail if the web app starts before AcrPull is effective; that's why the brief asks for a user-assigned identity.
- **MI and the schedule:** the stop schedule can't stop an MI with an active link, so it bills while linked. The schedule matters only after cutover.
- **Placeholder image:** the web app's outbound traffic goes through the hub firewall, which allows Microsoft Container Registry only. Don't use a placeholder from another public registry.
- **Codespaces** can run APEX Deploy because deployments are control-plane only. Data-plane checks (pushing images, browsing the app) must run from `vm-dev01`.
