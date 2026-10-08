# Archetype brief: CoE archetype for Contoso University (B09)

This is the input the owner pastes into APEX **Step 1 (02-Requirements)** in their own
repo, created from the
[`apex-accelerator`](https://github.com/jonathan-vella/apex-accelerator) template
(commit `bc96b7284eb116ab5c2ee71b9ba9510f4c22d99a` on `main`, checked 2026-10-05 — the
template has no tagged releases, so this is the pin; record the actual commit the
owner's repo was created from in `archetype/README.md`). It states every answer APEX's
Phase 1–4 questioning would otherwise ask for, so the agent should map these answers
directly instead of re-asking. Where this brief is silent, let APEX ask and record the
answer in the workflow state.

- **Project name (slug):** `university` — artifacts land in `agent-output/university/`,
  Bicep in `infra/bicep/university/`.
- **IaC tool:** Bicep only (`decisions.iac_tool = "bicep"`). Terraform is not used in
  this kit.
- **Region:** derive from the team's hub (`vnet-hub` in the shared services
  subscription) — `swedencentral`, fallback `germanywestcentral`. Don't hardcode; the
  generated Bicep takes `location` as a parameter.
- **Workload pattern:** containerized ASP.NET Core web app (Linux App Service) with a
  managed SQL database, blob storage, async messaging and centralized secrets/telemetry.
  This is the platform the Contoso University app (a .NET Framework 4.8 MVC app being
  modernized to .NET 10 in a separate workstream, B06/B10) will run on. APEX only builds
  the platform here — it does not modernize or deploy the app itself.
- **Compliance / environment:** deploys into an existing Corp landing zone spoke
  (`vnet-spoke`, already vended — see Inputs and derivation below). Every deny policy at
  `mg-factory-corp` (ALZ-lite, see `infra/foundation/README.md` in this repo) must pass.
  No production data; this is a training/demo environment, but security baselines are
  still enforced for realism.
- **Budget:** about $4.63/hour while fully deployed (see Cost below). No hard budget
  cap beyond the subscription's existing budget policy.

## Inputs and derivation (requirement 5)

Only three values are ever supplied by a human: **tenant ID**, **subscription ID**
(the workload subscription) and **suffix** (4–6 lowercase letters/digits, unique per
member). Everything else is discovered at deploy time, not hardcoded in the Bicep:

| Value | How it's found |
|---|---|
| Region | The hub's region, read from `vnet-hub` in the shared services subscription (peered to this workload subscription's `vnet-spoke`) |
| Spoke, subnets | By the backlog naming convention: `rg-spoke`, `vnet-spoke`, `snet-app`, `snet-pe`, `snet-sqlmi` — already vended, never created by the archetype |
| Hub / shared services subscription | Walk `vnet-spoke`'s peering to find the hub VNet and its subscription |
| Log Analytics workspace | `log-management` in `rg-management`, in the shared services subscription (ALZ-lite naming) |
| SQL MI Entra admin | The signed-in (deploying) user/principal |
| Resource names | CAF abbreviation + `university` + suffix, e.g. `app-university-<suffix>`, `acr-university-<suffix>` (no dashes in the ACR name — strip them) |

## Services and settings (requirement 2)

| Service | Settings |
|---|---|
| **App Service plan + web app** | Linux, container, SKU **P0v3**, 1 instance, zone redundancy off. VNet integration into `snet-app` with **all traffic routed through the VNet** (`vnetRouteAllEnabled: true`) and **image pull over the VNet**. **Public inbound stays on** — this is the only public backend endpoint in the archetype. HTTPS only, TLS 1.2 minimum. No private endpoint on the web app itself. *(🔎 VERIFY P0v3 supports regional VNet integration before committing to the SKU; if not, pick the smallest Premium v3 tier that does, and record the change as a deviation.)* |
| **Container registry** | Premium SKU; private endpoint in `snet-pe`; public network access off; admin user off; no `zones` (ACR is zone-redundant automatically, accepted per kit convention). **Allow trusted Azure services** (`networkRuleBypassOptions: AzureServices`) so `az acr import` works — document this as a deliberate, named exception, not an oversight. |
| **SQL Managed Instance** | General Purpose, **Standard-series (Gen5)**, 4 vCores, 64 GB storage, zone redundancy off, `databaseFormat: SameAsSource` is not used — set **`SQLServer2022`** explicitly. Entra-only authentication, admin = the deploying user. Public data endpoint off. Subnet `snet-sqlmi` (already delegated and NSG/route-tabled by vending — the archetype's Bicep must NOT declare `networkSecurityGroup`/route rules on this subnet or inline NSG/route rules that fight the MI's own network intent policy; see `infra/foundation/README.md`). `licenseType: 'BasePrice'` (Azure Hybrid Benefit). **`requestedBackupStorageRedundancy: 'Local'`** (not the Geo default — B07 finding 3, kit convention is LRS everywhere). A stop/start schedule (Automation or Logic App) for event hours — note in the Bicep/README that it can't stop the MI while an MI link is active, so it only takes effect after C7 cutover. No private endpoint: reached on its VNet-local host name. |
| **Storage account** | Standard general-purpose v2, LRS. Blob container `teaching-materials`. Private endpoint in `snet-pe`. Public network access off. Shared key access off (Entra/RBAC only). |
| **Service Bus** | Premium, 1 messaging unit. Queue `notifications`. Private endpoint in `snet-pe`. Public network access off. Local (SAS) auth off. No `zones` (zone-redundant automatically, accepted). |
| **Key Vault** | RBAC authorization (not access policies). Private endpoint in `snet-pe`. Public network access off. Soft delete on, purge protection **off** (this is a throwaway lab; purge protection would block teardown/redeploy cycles). |
| **Application Insights** | Workspace-based, attached to the central `log-management` workspace in the shared services subscription. Ingestion **stays public** — the documented private-only exception (Azure Monitor ingestion endpoints are already allowed through the hub firewall by vending, B08). |
| **Managed identity** | One **user-assigned** identity for the web app, created and role-assigned *before* the web app's first image pull (role propagation can take minutes — don't use the web app's own system-assigned identity for this reason). |

## Roles (requirement 3)

- **Web app's user-assigned identity:** `AcrPull` (on the registry), `Storage Blob Data
  Contributor` (on the storage account), `Azure Service Bus Data Sender` and `Azure
  Service Bus Data Receiver` (on the namespace), `Key Vault Secrets User` (on the vault).
- **The deploying member** (for local runs from `vm-dev01`): `AcrPush`, `Storage Blob
  Data Contributor`, `Azure Service Bus Data Sender` and `Receiver`, `Key Vault Secrets
  Officer`.
- A contained database user for the web app's identity on the MI is **out of scope
  here** — the MI starts as a read-only replica target and the user can only be created
  after C7 cutover (B07 finding). Note this as a follow-up for B11/C7, not a B09 gap.

## App settings the app reads (requirement 4)

Exact names, confirmed by the B06 golden-path report — don't rename them:

| Setting | Value |
|---|---|
| `Storage:BlobServiceUri` | The storage account's blob endpoint |
| `Storage:ContainerName` | `teaching-materials` |
| `ServiceBus:FullyQualifiedNamespace` | The namespace's FQDN |
| `ServiceBus:QueueName` | `notifications` |
| `KeyVault:VaultUri` | The vault's URI |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | The Application Insights connection string |
| (identity) | The user-assigned identity's client ID, as `AZURE_CLIENT_ID` (or the app's documented equivalent), so `DefaultAzureCredential` picks the right identity when running as the web app |

No secrets in app settings. `ConnectionStrings:DefaultConnection` is **not** an app
setting — it's a Key Vault secret (`ConnectionStrings--DefaultConnection`, Entra-only MI
connection string, `Authentication=Active Directory Default`, VNet-local host name),
read by the app through Key Vault references or at runtime. Populating that secret's
value is a C7 (migration) step, not part of the archetype deploy — the archetype only
needs the Key Vault and the role that lets the app read secrets from it.

## Private DNS (requirement 6)

The archetype creates **no** private DNS zones or zone groups. The landing zone's
DeployIfNotExists policies (ALZ-lite, B08) register the ACR/Blob/Service Bus/Key Vault
private endpoints into the central zones in the shared services subscription
automatically. SQL MI has no private endpoint and no private DNS zone: its VNet-local
host name resolves to its private IP through Azure DNS directly.

## Constraints — APEX security baseline (requirement 7)

- No public endpoints other than three **documented** exceptions: the web app's HTTPS
  front end, Application Insights ingestion, and ACR's trusted-Azure-services bypass for
  `az acr import`.
- Diagnostics from every resource to the central Log Analytics workspace.
- Managed identity everywhere (no connection-string secrets for Azure resource auth).
- Entra-only on SQL MI.
- No availability zones pinned, no zone redundancy turned on anywhere it's optional.
- Every ALZ-lite deny policy at `mg-factory-corp` must evaluate compliant for every
  resource this archetype creates.

## Initial image (requirement 8)

The web app starts from a placeholder image on Microsoft Container Registry (e.g.
`mcr.microsoft.com/dotnet/aspnet:10.0`), which the hub firewall allows outbound from
`snet-app` (vending, B08). It stays on the placeholder until C6/B10 pushes the real
`contoso-university` image.

## Azure Hybrid Benefit

SQL MI deploys with `licenseType: 'BasePrice'` (AHB on) by default, per the kit-wide
convention. Document in the generated README how to turn it off after deployment
(`az sql mi update --license-type LicenseIncluded`) and what it assumes (the partner
holds eligible SQL Server core licences with Software Assurance).

## Cost (for the brief's budget/NFR phase)

About $4.63/hour while fully deployed: SQL MI General Purpose 4 vCores with AHB ~$0.68,
Service Bus Premium ~$0.93, App Service P0v3 ~$0.10, ACR Premium ~$0.07, private
endpoints ~$0.05 (plus ALZ-lite ~$1.25 and the datacenter ~$1.55, which this brief's
workload doesn't deploy but which run alongside it in the kit).

## Notes for the owner running Step 1

- When APEX's Phase 3j asks for a SKU/sizing pin per service class, answer with the
  exact values in the **Services and settings** table above for every class — don't
  leave any class as "no preference", so every entry in `sku-manifest.json` is written
  `source: "user-pin"`.
- When asked about networking, answer "existing spoke, already vended" and point at the
  **Inputs and derivation** table — APEX should not create a new VNet, subnets, NSGs or
  route tables for `snet-app`, `snet-pe` or `snet-sqlmi`.
- Confirm Bicep (not Terraform) explicitly if asked.
- Pass every human gate and challenger review before handing off to Step 2
  (03-Architect). Record the repo URL and the commit once steps 1–5 are complete, and
  tell the executor so it can review and package the output.
