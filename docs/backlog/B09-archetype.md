# B09: Build the CoE archetype with APEX

| Field | Value |
|---|---|
| Milestone | P3 Build |
| Type | Both |
| Depends on | B06, B07, B08 |
| Unblocks | B10, B11 |
| Effort | 3–4 days elapsed, including the owner's APEX session |
| Cost | About $3.70/hour while deployed: Service Bus Premium about $0.93, App Service P0v3 about $0.10, ACR Premium about $0.07, private endpoints about $0.05, ALZ-lite about $1.25 and the datacenter about $1.30. The SQL MI free offer is free within its limits |
| Teardown | Delete everything this item created: the archetype resources, `rg-spoke` and `rg-datacenter` in the workload subscription, `rg-hub` and `rg-management` in the shared services subscription, the policy assignments and budget, and the kit's management groups after moving both subscriptions back to their original place |
| PRD | §2 Archetype, Compute, Messaging, Hybrid Benefit; §5 C5; §6 CoE archetype |

## Outcome

- `archetype/` holds the CoE archetype: an APEX project with steps 1–5 complete (artifacts, challenger reviews and workflow state) and the Bicep it produced, pinned to an APEX release.
- A member deploys it with APEX Deploy and As-Built, supplying only tenant ID, subscription ID and suffix. A plain `az deployment` script is the no-agent fallback.
- It deploys into a vended spoke, private-only and policy-compliant under ALZ-lite: App Service for Linux, ACR Premium, SQL MI free offer, Blob storage, Service Bus Premium, Key Vault and Application Insights, with the identities and roles the modernized app needs.

## Before you start

1. B06, B07 and B08 are closed. Read the B06 and B07 reports' recommendations for B09.
2. The workload subscription has no free-offer SQL MI (only one is allowed per subscription).
3. `.local/settings.json` has `tenantId`, `subscriptionId`, `location`, `memberIndex` and `suffix`.

## Requirements

### Brief for APEX

1. `archetype/BRIEF.md` is the input the owner gives APEX step 1. It states the requirements below as a workload brief, in APEX's terms, so that APEX's own agents make the architecture and code. It names the APEX release to use: the latest `apex-accelerator` release on the day, recorded in the brief.
2. The workload: hosting for a modernized .NET 10 web app (Contoso University) in a Corp landing zone spoke that already exists, private-only, with these services:

   | Service | Requirements |
   |---|---|
   | App Service plan and web app | Linux, container, SKU P0v3, one instance, zone redundancy off (🔎 VERIFY P0v3 supports VNet integration and private endpoints); VNet integration in `snet-app` with all traffic routed through the VNet and image pull over the VNet; private endpoint in `snet-pe`; public network access off; HTTPS only; TLS 1.2 minimum |
   | Container registry | Premium; private endpoint; public network access off; admin user off; **trusted Azure services allowed**, so `az acr import` of the known-good image works (B10). Document this as a deliberate exception |
   | SQL Managed Instance | General Purpose, **free offer**, 4 vCores, Standard-series hardware, 64 GB storage; in `snet-sqlmi`; reached on its VNet-local endpoint (no private endpoint); database format SQL Server 2022; Entra-only authentication with the deploying user as admin; public endpoint off; a stop and start schedule for the event hours, noting it only applies after cutover; `licenseType` as the B07 report found (AHB `BasePrice` if the free offer accepts it) |
   | Storage account | Standard general-purpose v2, LRS; Blob container `teaching-materials`; private endpoint; public network access off; shared key access off |
   | Service Bus | Premium, 1 messaging unit; queue `notifications`; private endpoint; public network access off; local auth off |
   | Key Vault | RBAC authorization; private endpoint; public network access off; soft delete on, purge protection off |
   | Application Insights | Workspace-based, on the central Log Analytics workspace. Ingestion stays public: the documented private-only exception (backlog conventions) |
   | Managed identity | One user-assigned identity for the web app, so roles exist before the first image pull |

3. Roles: the web app's identity gets AcrPull, Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, and Key Vault Secrets User. The deploying member gets AcrPush, Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, and Key Vault Secrets Officer, for local runs from the dev VM.
4. App settings the modernized app reads, named as the B06 report recommends: the Blob endpoint, the Service Bus namespace and queue, the Key Vault URI, the SQL MI host and database for managed identity, the identity's client ID and the Application Insights connection string. No secrets in app settings.
5. **Inputs:** only tenant ID, subscription ID and suffix. Everything else is derived or discovered: the hub (in the team's shared services subscription) from `vnet-spoke`'s peering, the region from the hub, the spoke and subnets by the backlog naming conventions, the Log Analytics workspace by its ALZ-lite name in the shared services subscription, and the MI Entra admin from the signed-in user. Resource names follow the conventions: CAF abbreviation + `university` + suffix.
6. **Private DNS:** the archetype doesn't create DNS zones or zone groups. The landing zone's DeployIfNotExists policy registers private endpoints in the central zones (ALZ-lite, B08), which live in the shared services subscription. SQL MI has no private endpoint: the app uses its VNet-local host name, which resolves to its private IP.
7. **Constraints** (APEX security baseline): no public endpoints apart from the two documented exceptions (Application Insights ingestion, and ACR trusted services for import), diagnostics to the central workspace, managed identity everywhere, Entra-only SQL, and every deny policy in ALZ-lite passes.
8. **Initial image:** the web app starts with a placeholder image from Microsoft Container Registry, which vending's firewall rules allow (B08), until the member pushes the real image in C6.

### APEX session

9. 🧑 HUMAN: the owner runs APEX steps 1–5 from their own device, in their own repo created from `apex-accelerator`, using `archetype/BRIEF.md`. They pass every human gate and challenger review, then tell the executor the repo and commit.
10. Review APEX's output against requirements 2–8 and list any gap in a table in the PR body. If a gap needs another APEX pass, 🧑 HUMAN: the owner re-runs the step, and you review again.

### Package

11. Copy the APEX project for the archetype (its artifacts, challenger sidecars, workflow state and Bicep) from the owner's repo at that commit into `archetype/`, keeping APEX's folder layout so it works when a member copies it into their own APEX repo. Don't copy anything unrelated to this project.
12. `archetype/README.md`: what the archetype is, which APEX release it's pinned to, how a member copies it into their APEX repo and deploys it with APEX Deploy (agent `07b`, workflow step 6) and As-Built (agent `08`, workflow step 7), the fallback deploy, the inputs, the cost per hour, the two private-only exceptions, and an **Azure Hybrid Benefit** section for SQL MI (what's on, how to turn it off). 🔎 VERIFY the agent IDs and step numbers against the pinned APEX release, and use that release's IDs everywhere.
13. A prompt file, placed where APEX loads prompts, named `deploy-archetype`: it asks for tenant ID, subscription ID and suffix, checks the prerequisites (vended spoke exists, signed in to the right subscription), then hands off to APEX Deploy and As-Built.
14. `archetype/deploy.ps1` (attendee script conventions): the no-agent fallback. It takes the same three inputs, discovers the rest the same way, and runs a plain `az deployment` of the archetype's Bicep. It prints the cost and that the MI provisions in the background.
15. `archetype/` must work in a member's APEX repo: 🔎 VERIFY with APEX's `apex-recall` (or its current equivalent) that the workflow state shows steps 1–5 complete and the Deploy step (agent `07b`) next.

### Validate for real

16. Deploy ALZ-lite (shared services subscription), then the datacenter and vending (member 1, workload subscription) with the kit scripts.
17. Deploy the archetype with `archetype/deploy.ps1`. Record the time until everything except the MI is ready, and the MI provisioning time.
18. 🧑 HUMAN: the owner copies `archetype/` into a fresh APEX repo and runs the `deploy-archetype` prompt against a clean spoke (delete the archetype resources first), then As-Built. Record the time and any gaps.
19. Check: no public endpoints beyond the two documented exceptions (every resource's public network access is off; no public IPs outside the hub and the datacenter NAT); zero non-compliant resources for the ALZ-lite policies in the archetype's resource group after evaluation; private endpoints registered in the central zones; the MI host name resolves to its private IP from `vm-dev01`; `scripts/Test-Connectivity.ps1` passes, including the private endpoint checks; from `vm-dev01`, push a test image to the registry and restart the web app with it; the web app pulls it with its identity and answers over its private endpoint; the web app's telemetry reaches Application Insights.
20. Tear everything down (Teardown row), including the subscription-level artifacts listed in the backlog conventions, and query each to confirm.

### Records

21. `versions.md`: the APEX release, the API versions APEX pinned for each service, and the MI database format, validated today.

## Deliverables

- `archetype/BRIEF.md`, `archetype/README.md`, `archetype/deploy.ps1`, the `deploy-archetype` prompt, and the APEX project output (artifacts, sidecars, workflow state, Bicep).
- `versions.md` updated.

## Verify

```powershell
Get-ChildItem archetype -Recurse -Filter *.bicep | ForEach-Object { az bicep lint --file $_.FullName }
Invoke-ScriptAnalyzer -Path archetype/deploy.ps1
npm run check
```

- Lint and PSScriptAnalyzer are clean.
- The PR body has the gap table, both deployment times, the checks from requirement 19 and the cost.

## Done when

- [ ] `archetype/` holds a complete APEX project, pinned and documented.
- [ ] The archetype deploys from only tenant ID, subscription ID and suffix, both through APEX and through the fallback.
- [ ] Every check in requirement 19 passes.
- [ ] Everything is torn down.

## Commit message

```text
feat: add the CoE archetype built with APEX
```

## Stop and ask if

- APEX's output differs from the brief in a way that changes cost, security or the app's contract.
- A deny policy blocks the archetype.
- The free-offer MI fails to provision, or the subscription already has one.

## Notes and traps

- **Markdown:** `archetype/` is excluded from the repo's Markdown lint (B01), because it's APEX output.
- **Role propagation:** role assignments can take minutes to apply. The first image pull can fail if the web app starts before AcrPull is effective; that's why the brief asks for a user-assigned identity.
- **MI and the schedule:** the free offer's stop schedule can't stop an MI with an active link. The schedule matters only after cutover.
- **Placeholder image:** the web app's outbound traffic goes through the hub firewall, which allows Microsoft Container Registry only. Don't use a placeholder from another public registry.
- **Codespaces** can run APEX Deploy because deployments are control-plane only. Data-plane checks (pushing images, browsing the app) must run from `vm-dev01`.
