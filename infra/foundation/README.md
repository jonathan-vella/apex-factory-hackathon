# Foundation: ALZ-lite, vending, exemptions and probes

The foundation is the team's landing zone. **ALZ-lite** is the small landing zone that attendees deploy: a management group hierarchy, a hub with Azure Firewall and central private DNS, a central Log Analytics workspace, and core policies. **Vending** puts each member's workload subscription under it and connects the member's spoke and datacenter to the hub. The team's platform lead runs both: ALZ-lite at Step 2 (T-7) and vending for every member at Step 4 (T-1), before the event (Day 1 starts with the kickoff intro and C1, and C2 tests an AI coding agent against the foundation's guardrails), through the platform pipeline or these scripts.

## Two subscriptions per member

Each platform team has one **shared services subscription**, which holds the hub and the workspace. Each member has a **workload subscription**, which holds the member's datacenter, spoke and archetype. `n` is a positive whole-number member index (`n >= 1`): indexes `1..255` use `10.10.n.0/24` (datacenter) and `10.20.n.0/24` (spoke), while indexes `256+` use non-overlapping `/24` blocks in `10.128.0.0/10` (`10.(127 + floor(n/256)).(n%256).0/24`) and `10.192.0.0/10` (`10.(191 + floor(n/256)).(n%256).0/24`). The diagram and tables below show `10.10.n.*` and `10.20.n.*` for `n = 1..255`.

```mermaid
flowchart TB
  root["Tenant Root"] --> mg["mg-factory"]
  mg --> plat["mg-factory-platform"]
  mg --> corp["mg-factory-corp<br/>core policies"]
  plat --> shared
  corp --> work
  subgraph shared["Shared services subscription (one per team)"]
    subgraph mgmt["rg-management"]
      law["log-management"]
      idmi["id-sqlmi-directory"]
    end
    subgraph hub["rg-hub"]
      vhub["vnet-hub 10.100.0.0/16<br/>afw-hub 10.100.0.4 (DNS proxy)<br/>afwp-hub"]
      dns["privatelink zones:<br/>Blob, Service Bus, ACR, Key Vault"]
    end
  end
  subgraph work["Workload subscription (one per member)"]
    subgraph dc["rg-datacenter"]
      vdc["vnet-datacenter 10.10.n.0/24<br/>vm-app01 .4, vm-dev01 .5<br/>NAT gateway for internet"]
    end
    subgraph spoke["rg-spoke"]
      vsp["vnet-spoke 10.20.n.0/24<br/>snet-app, snet-pe, snet-sqlmi"]
    end
  end
  vdc <-- "peering, UDR to the firewall" --> vhub
  vsp <-- "peering, UDR to the firewall" --> vhub
  dns -. "linked" .- vhub
```

The datacenter and the spoke aren't peered with each other: everything between them goes through the hub firewall, which allows only the rules below. The datacenter keeps its own internet egress on its NAT gateway, as an on-premises site would.

## Management groups

ALZ-lite creates this hierarchy under Tenant Root. The prefix is the `MgPrefix` parameter (default `mg-factory`), so several kits can coexist in one tenant.

| Management group | Parent | Holds |
|---|---|---|
| `mg-factory` | Tenant Root | — |
| `mg-factory-platform` | `mg-factory` | The shared services subscription (moved by ALZ-lite) |
| `mg-factory-corp` | `mg-factory` | Members' workload subscriptions (moved by vending), and the core policies |

## ALZ-lite compared with a full ALZ

| Control | Full ALZ (kickoff slides or recording) | ALZ-lite |
|---|---|---|
| Management groups | Intermediate root, Platform (Management, Connectivity, Identity), Landing zones (Corp, Online), Sandbox, Decommissioned | `mg-factory` with `-platform` and `-corp` |
| Hub networking | Hub VNet or Virtual WAN, Azure Firewall, VPN or ExpressRoute gateways, DDoS Network Protection, Bastion | `vnet-hub` with Azure Firewall Standard and DNS proxy. No gateways (the datacenter is peered: simulated ExpressRoute), DDoS off |
| DNS | Private DNS zones for every service, often a DNS Private Resolver | Four privatelink zones (Blob, Service Bus, ACR, Key Vault) linked to the hub; the firewall's DNS proxy forwards to Azure DNS |
| Logging | Central Log Analytics, Azure Monitor Agent and data collection rules, Sentinel option | `log-management` (30-day retention); diagnostics policies for the archetype's resource types |
| Policies | The ALZ policy library (hundreds of definitions in many initiatives) | 19 built-in assignments at `mg-factory-corp` (below) |
| Defender for Cloud | Paid plans per resource type | Foundational CSPM only (free); every paid plan off, unless `-SkipDefender` |
| Identity | Identity subscription, domain controllers, privileged access | None: Entra ID only |
| Subscription vending | Subscription creation, budgets, RBAC, networking | Places pre-created subscriptions; spoke, peering, UDRs, DNS, firewall rules, Owner for the member, budget |

## Policies at `mg-factory-corp`

Built-in definitions only, display names prefixed `ALZ-lite:`. The definition IDs were checked with `az policy definition list` on 2026-10-02.

| Assignment | Definition | ID | Effect |
|---|---|---|---|
| `alzl-allowed-locations` | Allowed locations | `e56962a6-4747-49cd-b67b-bf8b01975c4c` | Audit (owner decision 2026-10-06): other regions show as non-compliant but aren't blocked. `location` and `global`, plus `-AdditionalAllowedLocation` (for example the fallback region) |
| `alzl-location-match-rg` | Audit resource location matches resource group location | `0a914e76-4921-4c19-b460-a2d36003525a` | Audit (owner decision 2026-10-06). `global` resources are excluded by the definition |
| `alzl-deny-nic-pip` | Network interfaces should not have public IPs | `83a86a26-fd1f-447c-b59d-e51f44264114` | Deny (fixed in the definition) |
| `alzl-deny-pna-storage` | Storage accounts should disable public network access | `b2982f36-99f2-4db5-8eff-283140c09693` | Deny |
| `alzl-deny-pna-keyvault` | Azure Key Vault should disable public network access | `405c5871-3e91-4644-8a63-58e19d68ff5b` | Deny |
| `alzl-deny-pna-servicebus` | Service Bus Namespaces should disable public network access | `cbd11fd3-3002-4907-b6c8-579f0e700e13` | Deny |
| `alzl-deny-pna-acr` | Public network access should be disabled for Container registries | `0fdf0491-d080-4575-b627-ad0e843cba0f` | Deny |
| `alzl-deny-pna-sqlmi` | Azure SQL Managed Instances should disable public network access (the public data endpoint) | `9dfea752-dd46-4766-aed1-c355fa93fb91` | Deny |
| `alzl-dns-blob` | Configure a private DNS Zone ID for blob groupID | `75973700-529f-4de2-b794-fb9b6781b6b0` | DeployIfNotExists |
| `alzl-dns-servicebus` | Configure Service Bus namespaces to use private DNS zones | `f0fcf93c-c063-4071-9668-c47474bd3564` | DeployIfNotExists |
| `alzl-dns-acr` | Configure Container registries to use private DNS zones | `e9585a95-5b8c-4d03-b193-dc7eb5ac4c32` | DeployIfNotExists |
| `alzl-dns-keyvault` | Configure Azure Key Vaults to use private DNS zones | `ac673a9a-f77d-4846-b2d8-a57f8e1c01d4` | DeployIfNotExists |
| `alzl-diag-appservice` | Enable logging by category group for App Service (microsoft.web/sites) to Log Analytics | `c0d8e23a-47be-4032-961f-8b0ff3957061` | DeployIfNotExists |
| `alzl-diag-sqlmi` | Enable logging by category group for SQL managed instances to Log Analytics | `8fc4ca5f-6abc-4b30-9565-0bd91ac49420` | DeployIfNotExists |
| `alzl-diag-keyvault` | Enable logging by category group for Key vaults to Log Analytics | `6b359d8f-f88d-4052-aa7c-32015963ecc1` | DeployIfNotExists |
| `alzl-diag-servicebus` | Enable logging by category group for Service Bus Namespaces to Log Analytics | `0277b2d5-6e6f-4d97-9929-a5c4eab56fd7` | DeployIfNotExists |
| `alzl-diag-acr` | Enable logging by category group for Container registries to Log Analytics | `56288eb2-4350-461d-9ece-2bb242269dce` | DeployIfNotExists |
| `alzl-diag-appinsights` | Enable logging by category group for Application Insights to Log Analytics | `79494980-ea12-4ca1-8cca-317e942b6da2` | DeployIfNotExists |
| `alzl-diag-blob` | Configure diagnostic settings for Blob Services to Log Analytics workspace | `b4fe1a3b-0715-4c6c-a5ea-ffc33cf823cb` | DeployIfNotExists |

Not covered on purpose: App Service public network access (the web front end is public by design) and a private DNS zone for SQL MI (it has no private endpoint here; its VNet-local host name resolves to its private IP through Azure DNS, and a `privatelink` zone could break its management operations).

The DeployIfNotExists assignments have system-assigned identities. The private DNS ones get Network Contributor at `mg-factory-corp` and on `rg-hub`; the diagnostics ones get Log Analytics Contributor at `mg-factory-corp` and on `rg-management` (Blob also Monitoring Contributor at `mg-factory-corp`). They act on new and changed resources, typically within 30 minutes; existing resources need a remediation task.

## Vending inputs

`scripts/Deploy-Vending.ps1` finds the hub's IDs by the ALZ-lite names and passes them to `infra/foundation/vending/main.bicep`:

| Parameter | Default | Notes |
|---|---|---|
| `WorkloadSubscriptionId` | — | The member's subscription, moved into `mg-factory-corp` |
| `SharedSubscriptionId` | — | Where the hub is |
| `MemberIndex` | `1` | `n >= 1`: for `1..255`, spoke `10.20.n.0/24` and datacenter `10.10.n.0/24`; for `256+`, `10.(191 + floor(n/256)).(n%256).0/24` and `10.(127 + floor(n/256)).(n%256).0/24` |
| `Location` | `swedencentral` | |
| `MgPrefix` | `mg-factory` | As passed to ALZ-lite |
| `MemberPrincipalId` | empty | The member's object ID, who gets workload Owner, direct shared-services Reader, and Managed Identity Operator on `id-sqlmi-directory`. When supplied, vending requires their kit management-group Reader access to come from the foundation group |
| `ReaderGroupId` | empty | The foundation reader group's Entra object ID. Required for foundation apply and for vending with a member principal |
| `BudgetAmount` | `500` | A month, in the billing currency |
| `BudgetEmail` | — | Alert at 80% of actual cost |
| `SkipDefender` | off | Leave the subscription's Defender for Cloud plans as they are (see [Defender for Cloud](#defender-for-cloud)) |
| `ShowIds` | off | Print the hub's full resource IDs, including the shared services subscription ID. By default the ID is masked |

Found in the shared services subscription: `vnet-hub`'s ID, `afw-hub`'s private IP, `afwp-hub`'s ID, `rg-hub`'s ID (the DNS zones) and `log-management`'s ID. Vending connects the datacenter only if `vnet-datacenter` exists, so run it after the datacenter, and run it again after any datacenter redeploy: `Deploy-Datacenter.ps1` resets `snet-servers` (dropping `rt-servers`) and `vnet-datacenter`'s DNS servers. After vending, the running VMs pick up the hub DNS only after a restart; the script prints the `az vm restart` commands. Record the datacenter's policy exemptions again after a datacenter redeploy.

The script prints the hub's resource IDs, which contain the shared services subscription ID, with the subscription ID masked. Pass `-ShowIds` to print them in full. Don't commit output that shows a subscription ID.

What it deploys:

| Where | What |
|---|---|
| Tenant | The workload subscription moved into `mg-factory-corp` |
| `rg-spoke` | `vnet-spoke` `10.20.n.0/24` with DNS `afw-hub`; `snet-app` `10.20.n.0/26` (delegated to `Microsoft.Web/serverFarms`, `rt-app`); `snet-pe` `10.20.n.64/26` (`rt-pe`); `snet-sqlmi` `10.20.n.128/26` (delegated to `Microsoft.Sql/managedInstances`, `nsg-sqlmi`, `rt-sqlmi`); peering `peer-spoke-to-hub` |
| `nsg-sqlmi`, `rt-sqlmi` | Created once, empty: a PUT without the rules and routes that SQL MI's network intent policy adds would remove them (B08 validation), so re-runs leave both alone. The kit's rules and route are child resources. `nsg-sqlmi`: MI link rules from the B07 report, inbound TCP 5022 and 11000–11999 from `10.10.n.4`, outbound TCP 5022 to `10.10.n.4`; diagnostics to `log-management` |
| `rg-datacenter` | Peering `peer-datacenter-to-hub`; `rt-servers` on `snet-servers`; `vnet-datacenter` DNS set to `afw-hub` (after the peering) |
| `rg-hub` | Peerings `peer-hub-to-spoke-n` and `peer-hub-to-datacenter-n`; rule collection group `rcg-member-n` in `afwp-hub` |
| `<MgPrefix>` | One Reader assignment to `<MgPrefix>-readers`, deployed by foundation |
| Shared services subscription | Reader for the member (if `-MemberPrincipalId` is set) |
| Workload subscription | Owner for the member; budget `budget-factory-workload`; Defender for Cloud on Foundational CSPM only (unless `-SkipDefender`) |

The platform lead runs vending serially because each run updates `afwp-hub`. Workload Owner, direct shared-subscription Reader and Managed Identity Operator on `id-sqlmi-directory` are unchanged. The foundation reader group grants control-plane Reader at `<MgPrefix>` and every current or future descendant subscription, including other members' workloads. It grants no data access or rights at Tenant Root. Use only a dedicated lab hierarchy. `/apex-adapt-archetype` can discover policies at kit scopes, but policies above `<MgPrefix>` may still report `PARTIAL`.

### Prepare and sync the reader group

The team lead or an authorized Entra operator runs these commands interactively from the kit. Install `Microsoft.Graph.Authentication` first. Use an approved delegated Graph client in the event tenant (`-GraphClientId` if required); activate the least privileged eligible PIM role only if the tenant requires it. Bootstrap uses delegated `Group.ReadWrite.All`. Sync uses a group owner's delegated `GroupMember.ReadWrite.All` and `Directory.Read.All` to validate roster object types. Azure Owner alone doesn't grant Graph access. GitHub Actions receives no new Graph permissions.

```powershell
# Before Step 2 foundation; Bootstrap can create the group with no members yet.
./scripts/Sync-FactoryReaderGroup.ps1 -Mode Bootstrap -TenantId '<tenant-id>' -MgPrefix mg-factory -OwnerId '<lead-object-id>' -Repository 'owner/lead-repo' -WhatIf
# Repeat without -WhatIf after reviewing the target.

# Before Step 4, or before an all run; use the complete private roster even when vending a subset.
./scripts/Sync-FactoryReaderGroup.ps1 -Mode Sync -TenantId '<tenant-id>' -MgPrefix mg-factory -RosterPath .local/roster.json -Repository 'owner/lead-repo' -WhatIf
# Repeat without -WhatIf to reconcile membership and publish the verified roster.
```

Use the actual kit prefix in both commands. The GitHub publisher needs access to the lead repo's `gh-lab` environment. Bootstrap publishes `READER_GROUP_ID`; sync publishes `ROSTER_JSON` and `READER_ROSTER_VERIFICATION` only after membership is verified. For a one-member lab without a roster file, supply `-MemberIndex`, `-WorkloadSubscriptionId`, `-MemberPrincipalId` and `-BudgetEmail` to Sync. If workload subscriptions change, first update the pipeline allowlist with `Initialize-PlatformPipeline.ps1`. Run Sync again after roster or group changes; it removes direct members absent from the roster, but does not revoke anyone's separately assigned Azure roles. Use nested security groups only for dedicated roster slots whose membership the lead controls.

For an existing lab, first sync the group and redeploy foundation. Verify with a rostered non-admin test user who has no direct Reader at `<MgPrefix>` (use a member of the nested group too, if applicable). Then preview and separately approve migration:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope LegacyReader -MgPrefix mg-factory -ReaderGroupId '<reader-group-id>' -VerificationPrincipalId '<test-user-object-id>' -WhatIf
```

After review, repeat without `-WhatIf`. This removes only deterministic vending-marked Reader assignments at the exact kit scope, including grants to former members, not manual Reader grants or the new group binding. Removing the old module from incremental Bicep does not remove existing assignments.

**SQL MI directory identity (event prep, once per team).** ALZ-lite creates `id-sqlmi-directory` in `rg-management`. Every member's SQL Managed Instance uses it as its primary identity, so `CREATE USER ... FROM EXTERNAL PROVIDER` can look up Microsoft Entra principals, such as the web app's identity in C7. A Privileged Role Administrator grants it Microsoft Graph read permissions once per team (see [Event prep: SQL MI directory identity](#event-prep-sql-mi-directory-identity); [Managed identities in Microsoft Entra for Azure SQL](https://learn.microsoft.com/azure/azure-sql/database/authentication-azure-ad-user-assigned-managed-identity)). Without it, creating the web app's database user fails with "Server identity does not have Azure Active Directory Readers permission" (B09 validation, 2026-10-07).

## Firewall rules

`rcg-member-n` (priority `1000 + n`) allows only these flows. Anything else through the firewall is denied.

| Rule | Type | From | To | Ports | Why |
|---|---|---|---|---|---|
| `dev-to-private-endpoints` | Network | `vm-dev01` `10.10.n.5` | `snet-pe` `10.20.n.64/26` | TCP 443, 5671 | Members push images to ACR, and run the app locally against Blob, Service Bus (AMQP on 5671) and Key Vault |
| `dev-to-app` | Network | `vm-dev01` | `snet-app` `10.20.n.0/26` | TCP 443 | Reach the app's integration subnet from the dev VM |
| `dev-to-sqlmi` | Network | `vm-dev01` | `snet-sqlmi` `10.20.n.128/26` | TCP 1433, 11000–11999 | SSMS, `sqlcmd` and the perf kit against the MI (redirect ports) |
| `milink-sqlserver-to-mi` | Network | `vm-app01` `10.10.n.4` | `snet-sqlmi` | TCP 5022, 11000–11999 | MI link, SQL Server to MI (B07 report) |
| `milink-mi-to-sqlserver` | Network | `snet-sqlmi` | `vm-app01` | TCP 5022 | MI link, MI to SQL Server (B07 report) |
| `app-to-entra-id` | Network | `snet-app` | Service tag `AzureActiveDirectory` | TCP 443 | The app's managed identity and Entra sign-in |
| `app-to-mcr` | Application | `snet-app` | `mcr.microsoft.com`, `*.data.mcr.microsoft.com` | HTTPS 443 | The archetype's placeholder image |
| `app-to-azure-monitor` | Application | `snet-app` | `dc.applicationinsights.azure.com`, `dc.applicationinsights.microsoft.com`, `dc.services.visualstudio.com`, `*.in.applicationinsights.azure.com`, `live.applicationinsights.azure.com`, `rt.applicationinsights.microsoft.com`, `rt.services.visualstudio.com`, `*.livediagnostics.monitor.azure.com` | HTTPS 443 | Application Insights ingestion and Live Metrics: the documented private-only exception (endpoints from [Azure Monitor network access](https://learn.microsoft.com/azure/azure-monitor/fundamentals/azure-monitor-network-access), checked 2026-10-02) |

Traffic inside the spoke (the app to its private endpoints and to the MI) stays in `vnet-spoke`: the VNet's own route is more specific than the `0.0.0.0/0` UDR.

**SNAT for private endpoints and Azure scale limits.** Traffic to private endpoints that the firewall inspects with network rules must be source-NATed to keep the flow symmetric ([Azure Firewall scenarios to inspect traffic destined to a private endpoint](https://learn.microsoft.com/azure/private-link/inspect-traffic-with-azure-firewall)). `afwp-hub` pre-populates the hub, datacenter (`10.10.0.0/16` and `10.128.0.0/10`), and standard spoke (`10.20.1..255.0/26` and `10.20.1..255.128/25`) non-PE ranges at foundation time so members `1` to `255` require no parent policy update during vending; overflow indexes (`256` up to IPv4 pool capacity `16,639` in `10.192.0.0/10`) append their non-PE prefixes dynamically during serialized vending and are preserved across foundation re-runs. Every member's `snet-pe` (`.64/26`) stays excluded and source-NATed while MI link and management flows keep the real source IP. Single-hub platform limits apply: Azure Firewall allows up to **90 rule collection groups per firewall policy** (above 90 members, split across hubs/policies), GitHub's `ROSTER_JSON` secret limit (`48 KiB`) holds roughly **250 members**, GitHub Actions matrices cap at **256 jobs per run**, and Azure Virtual Network supports up to **650 peerings per hub VNet** (**325 members** at two peerings—datacenter and spoke—per member).

## Routes

| Route table | Subnet | Route | Next hop | Why |
|---|---|---|---|---|
| `rt-app` | `snet-app` | `0.0.0.0/0` | `afw-hub` | App Service outbound goes through the firewall rules above |
| `rt-pe` | `snet-pe` | `0.0.0.0/0` | `afw-hub` | Anything leaving the endpoint subnet is inspected |
| `rt-sqlmi` | `snet-sqlmi` | `10.10.n.0/24` | `afw-hub` | MI link to the datacenter through the firewall. Only this range: MI keeps the routes its network intent policy adds, including its own internet route |
| `rt-servers` | `snet-servers` | `10.20.n.0/24` | `afw-hub` | The datacenter reaches the spoke through the firewall; internet egress stays on `nat-datacenter` |

## DNS

`vnet-spoke` and `vnet-datacenter` use `afw-hub`'s private IP as their DNS server. The firewall's DNS proxy forwards to Azure DNS in `vnet-hub`, where the privatelink zones are linked, so private endpoint names resolve to private IPs from the datacenter and the spoke. SQL MI's host name resolves to its private IP through the same path, without a zone. Running VMs pick up the new DNS server after a restart or `ipconfig /renew`.

## Exemptions

The datacenter existed before vending moved the workload subscription into `mg-factory-corp`, so the deny policies didn't block it, but it can show as non-compliant. `scripts/New-DatacenterExemptions.ps1` scans `rg-datacenter` and finds the policy assignments it violates. It creates one exemption for each **ALZ-lite** assignment (display name `ALZ-lite: ...`) among them, plus any assignment named with `-IncludeAssignment`, scoped to `rg-datacenter` only: category Waiver, an expiry date (default 14 days), and a description with the owner, the reason ("pre-existing on-premises simulation, migrating in C7") and the target date. Other violated assignments are listed but never exempted unless named. It prints a table for the deferred-work register. It never exempts the spoke or the workload resources. That's the lesson (PRD §4): deferred work needs an owner, a target and a timeline.

The core policies target what the archetype deploys, so a fresh datacenter violates none of them (B08 validation). The policy the simulated on-premises servers legitimately fail is the **Microsoft cloud security benchmark**, which Defender for Cloud assigns in most tenants (for example as "Azure Security Baseline" or "ASC Default"). Name it to exempt it:

```powershell
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId <subscription-id> -Owner '<owner name>' -IncludeAssignment 'Azure Security Baseline' -WhatIf
```

Run it with `-WhatIf` first to see what it would create.

## Probes

`scripts/Test-Connectivity.ps1` checks the network contract and reports PASS or FAIL per check, then a verdict (exit code 0 or 1):

- In Azure: both peerings `Connected`, both VNets' DNS set to the firewall, `snet-servers` on the NAT gateway with the spoke route, and the four zones linked to `vnet-hub`.
- From `vm-dev01` (VM run command): the VM uses the firewall for DNS and the DNS proxy answers; each private endpoint in `snet-pe` resolves into `snet-pe` and connects on its port (443, plus 5671 for Service Bus); `vm-app01` answers on 80 and 1433; internet egress works.
- From `vm-app01` (an Arc run command once it's Arc-enabled, a VM run command before): the same DNS checks and, if a SQL MI exists in `snet-sqlmi`, that its host name resolves into `snet-sqlmi` and TCP 5022 and 11000 connect.

It skips the checks that don't apply yet and says so: private endpoints and the MI arrive with the archetype. An empty private zone's SOA looks the same as the public one, so the private endpoint checks are what prove private resolution end to end. The in-VM checks are in [scripts/Test-HubConnectivity.ps1](scripts/Test-HubConnectivity.ps1).

## Permissions

The platform lead needs **Owner at the Tenant Root management group**: to create the management groups, move both subscriptions, assign policies and give their identities roles, and write to both subscriptions in vending. Both deploy scripts check it first. To get it, a Global Administrator elevates access (Microsoft Entra ID > Properties > Access management for Azure resources) and assigns Owner at Tenant Root.

## Event prep: SQL MI directory identity

Once per team, at T-7 right after the platform lead deploys ALZ-lite (and before C7), someone with **Privileged Role Administrator** (or Global Administrator) in the event tenant grants `id-sqlmi-directory` its Microsoft Graph read permissions. Members and the platform lead usually can't: it's a directory role, not an Azure role. Without it, C7 can't create the web app's database user on any member's SQL Managed Instance.

1. If the role is assigned through Privileged Identity Management, activate it first: in the Microsoft Entra admin center, go to **Identity governance > Privileged Identity Management > My roles**, then **Activate**. From the command line, use Microsoft Graph PowerShell; the Azure CLI's sign-in can't activate PIM roles:

   ```powershell
   Install-Module Microsoft.Graph.Identity.Governance -Scope CurrentUser   # once
   Connect-MgGraph -Scopes 'RoleAssignmentSchedule.ReadWrite.Directory' -TenantId '<tenant-id>'
   $userId = (Invoke-MgGraphRequest GET 'https://graph.microsoft.com/v1.0/me').id
   New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter @{
     action           = 'selfActivate'
     principalId      = $userId
     roleDefinitionId = 'e8611ab8-c189-46e8-94e1-60213ab1f814'   # Privileged Role Administrator
     directoryScopeId = '/'
     justification    = 'Hackathon prep: SQL MI directory identity'
     scheduleInfo     = @{ startDateTime = (Get-Date).ToUniversalTime().ToString('o'); expiration = @{ type = 'AfterDuration'; duration = 'PT1H' } }
   }
   ```

   The tenant's PIM settings may require approval or MFA, in which case the request stays pending until it's approved. An existing `az login` session picks up the activated role without signing in again (B09 validation, 2026-10-07).
2. Grant the permissions:

   ```powershell
   $s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
   ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId
   ```

3. Check: the same command with `-WhatIf` prints "already granted" for `User.Read.All`, `GroupMember.Read.All` and `Application.Read.All`. Anyone signed in to the tenant can run the check; it changes nothing.

The grant belongs to the identity. Re-running ALZ-lite keeps the identity and its permissions; deleting `rg-management` (teardown) deletes both, so a redeploy after teardown needs the grant again.

## Run it

```powershell
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -WhatIf
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -ReaderGroupId '<reader-group-id>'
./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId   # once per team, Privileged Role Administrator
./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex -MemberPrincipalId '<member-object-id>' -ReaderGroupId '<reader-group-id>' -BudgetEmail '<email>'
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId $s.subscriptionId -Owner '<owner name>'
./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
```

## Defender for Cloud

By default both deploy scripts set Microsoft Defender for Cloud to **Foundational CSPM** (free) on their subscription, with `Microsoft.Security/pricings`: every paid plan (servers, SQL, App Service, storage, Key Vault, Resource Manager, containers, Cosmos DB, open-source databases, Defender CSPM, APIs, AI) is turned **off subscription-wide**, including for resources the kit didn't create. Event subscriptions are dedicated to the kit, so attendees keep the default.

`-SkipDefender` (on `Deploy-AlzLite.ps1` and `Deploy-Vending.ps1`) leaves the subscription's plans as they are. Use it only in a subscription that also hosts other workloads, such as the kit's build subscriptions (owner decision, 2026-10-02).

## Zones and public endpoints

No resource sets `zones`. `afw-hub` has no zone. `pip-afw-hub` is a Standard public IP, zone-redundant automatically, and the foundation's only public IP. Nothing in vending has a public IP.

## Cost

| Item | Cost while deployed |
|---|---|
| Azure Firewall Standard (`afw-hub`) | About $1.30/hour, plus $0.016/GB processed |
| `pip-afw-hub` | About $0.005/hour |
| `log-management` | Pay per GB ingested; low volume in the lab |
| Private DNS zones | About $0.50 a zone a month |
| Vending (VNets, route tables, NSGs, peering) | No hourly cost; peering traffic is billed per GB |

ALZ-lite costs about $1.30/hour per team, mostly the firewall, until `rg-hub` is deleted. Defender for Cloud stays on Foundational CSPM (free).

## API versions

Pinned, not preview, except `Microsoft.Insights/diagnosticSettings@2021-05-01-preview`: it has no GA version for diagnostic settings on a resource. Exemptions are created with `az policy exemption create`, because `Microsoft.Authorization/policyExemptions` has only preview API versions.
