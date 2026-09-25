# B08: Build the foundation: ALZ-lite, vending, probes and exemptions

| Field | Value |
|---|---|
| Milestone | P3 Build |
| Type | Both |
| Depends on | B02, B07 |
| Unblocks | B09, B11 |
| Effort | 2–3 days |
| Cost | About $2.85/hour while deployed: Azure Firewall Standard about $1.25/hour plus its public IP, Log Analytics at low volume, and the datacenter (redeployed for testing) at about $1.55/hour |
| Teardown | Delete everything this item created: `rg-hub` and `rg-management` in the shared subscription; `rg-spoke` and `rg-datacenter` in the workload subscription; the policy assignments, exemptions, role assignments and budget. Move both subscriptions back under Tenant Root, then delete the kit's management groups |
| PRD | §2 Tenancy, Foundation, Kit build; §4; §5 C2; §6 Foundation |

## Outcome

- **ALZ-lite** is the kit's landing zone, and the one attendees deploy. For each team it creates a small management group hierarchy, puts the team's **shared services subscription** under `mg-platform` with a hub (Azure Firewall Standard with DNS proxy, central private DNS zones) and a central Log Analytics workspace, and assigns the core policies at `mg-corp`.
- **Vending** puts a member's **workload subscription** under `mg-corp` and connects it to the hub: the spoke and all its subnets, peering, UDRs, DNS, firewall rules, RBAC and a budget. It also connects the member's datacenter to the hub.
- **Probes** check DNS and ports from the dev VM and the app VM. **Exemptions** record the datacenter's deliberate policy exceptions, with owner and expiry.

Full portal ALZ is out of scope: a coach demos it live at the event, without kit scripts (PRD §2).

## Before you start

1. B02 and B07 are closed. Read the MI link network rules in the B07 report.
2. `.local/settings.json` has `tenantId`, `sharedSubscriptionId`, `subscriptionId` (the workload subscription), `location`, `memberIndex` and `suffix`.
3. The signed-in user is Owner on both subscriptions and can create management groups and move subscriptions (Owner, or Management Group Contributor plus the right to move subscriptions, at the Tenant Root group). If not, stop and ask.
4. `rg-hub` and `rg-management` don't exist in the shared subscription, and `rg-spoke` and `rg-datacenter` don't exist in the workload subscription. B07 deleted the datacenter; this item deploys a fresh one for its tests.
5. Record where both subscriptions sit in the management group hierarchy now, so teardown can put them back.

## Requirements

### Management groups

1. ALZ-lite creates this hierarchy under Tenant Root. The prefix is a parameter (`mgPrefix`, default `mg-factory`) so several kits can coexist:

   | Management group | Parent | Holds |
   |---|---|---|
   | `mg-factory` | Tenant Root | — |
   | `mg-factory-platform` | `mg-factory` | The team's shared services subscription |
   | `mg-factory-corp` | `mg-factory` | Members' workload subscriptions (placed by vending) |

2. ALZ-lite moves the shared services subscription into `mg-factory-platform`. Vending moves each workload subscription into `mg-factory-corp`.

### ALZ-lite: shared services subscription

3. `infra/foundation/alz-lite/main.bicep` deploys, in the shared services subscription:

   | Resource group | Resource | Name | Settings |
   |---|---|---|---|
   | `rg-management` | Log Analytics workspace | `log-management` | 30-day retention |
   | `rg-hub` | VNet | `vnet-hub` | `10.100.0.0/16`, with `AzureFirewallSubnet` `10.100.0.0/26` |
   | `rg-hub` | Azure Firewall | `afw-hub` | Standard, no zones, public IP `pip-afw-hub` (Standard, no `zones` set: zone-redundant automatically), firewall policy `afwp-hub` with **DNS proxy on**, diagnostics to `log-management` |
   | `rg-hub` | Private DNS zones | The `privatelink` zones for Blob, Service Bus, ACR, Key Vault and App Service | Linked to `vnet-hub` |

   🔎 VERIFY the zone names on [Azure private endpoint DNS zone values](https://learn.microsoft.com/azure/private-link/private-endpoint-dns). There's no zone for SQL MI: clients use its VNet-local endpoint, which Azure DNS resolves to its private IP (see **Notes and traps**).

### ALZ-lite: policies at `mg-factory-corp`

4. Policies assigned at `mg-factory-corp`, with built-in definitions only, each with a display name prefixed `ALZ-lite:`:

   | Policy | Effect | Notes |
   |---|---|---|
   | Allowed locations | Deny | `location` and `global`; parameterized, so the fallback region can be added |
   | Network interfaces shouldn't have public IPs | Deny | |
   | Public network access disabled for Storage, Key Vault, Service Bus, ACR and App Service, and the public data endpoint disabled for SQL MI | Deny | One assignment per service, or an initiative |
   | Private endpoints register in the central private DNS zones | DeployIfNotExists | For Storage (Blob), Service Bus, ACR, Key Vault and App Service, pointing at the zones in the shared subscription's `rg-hub`. The assignment's managed identity gets the roles it needs on that resource group. Not for SQL MI |
   | Diagnostic settings to `log-management` | DeployIfNotExists | For the resource types the archetype deploys, sending to the workspace in the shared subscription |

   🔎 VERIFY each built-in definition ID with `az policy definition list`. Record the IDs in `infra/foundation/README.md`.
5. Microsoft Defender for Cloud stays on **Foundational CSPM** (free) on both subscriptions: every paid plan off, set with `Microsoft.Security/pricings`.
6. `scripts/Deploy-AlzLite.ps1` (attendee script conventions) deploys requirements 1–5 for a team. Parameters: `SharedSubscriptionId`, `Location`, `MgPrefix`. It checks the management group permissions first and explains how to get them if missing (Owner at Tenant Root, or a Global Admin elevating access). It prints the cost per hour and how long it took. A re-run converges.

### Vending: workload subscription

7. `infra/foundation/vending/main.bicep` connects one member's workload subscription to the team's hub. It takes the hub by parameters (hub VNet ID, firewall private IP, firewall policy ID, DNS zone resource group ID, Log Analytics workspace ID). It deploys:
   - the subscription's placement under `mg-factory-corp`;
   - `rg-spoke` with `vnet-spoke` `10.20.n.0/24` and the subnets from the backlog conventions (`snet-app` delegated to `Microsoft.Web/serverFarms`, `snet-pe`, `snet-sqlmi` delegated to `Microsoft.Sql/managedInstances` with the NSG and route table MI needs);
   - peering both ways, across the two subscriptions, between `vnet-spoke` and `vnet-hub`, and between `vnet-datacenter` and `vnet-hub` if the datacenter exists;
   - DNS servers on `vnet-spoke` and `vnet-datacenter` set to the firewall's private IP;
   - UDRs: `snet-app` and `snet-pe` send `0.0.0.0/0` to the firewall; `snet-sqlmi` sends only the datacenter range to the firewall, keeping MI's own routes; `snet-servers` sends the spoke range to the firewall and keeps internet egress on the NAT gateway;
   - a rule collection group for member `n` in `afwp-hub`, allowing only: dev VM to `snet-pe` and `snet-app` on 443 (and 5671 for Service Bus); dev VM to `snet-sqlmi` on 1433 and 11000–11999; MI link between `10.10.n.4` and `snet-sqlmi` (the rules from the B07 report); App Service outbound to Entra ID, to Microsoft Container Registry (`mcr.microsoft.com` and its data endpoints, for the archetype's placeholder image) and to the Azure Monitor ingestion endpoints (the documented private-only exception; 🔎 VERIFY the endpoints on [Azure Monitor network access](https://learn.microsoft.com/azure/azure-monitor/fundamentals/azure-monitor-network-access));
   - Owner on the workload subscription for the member (a parameter; skipped when empty);
   - a monthly budget on the workload subscription (parameter, default 500 in the billing currency) with an alert at 80% to an email parameter.
8. `scripts/Deploy-Vending.ps1` deploys it. Parameters: `WorkloadSubscriptionId`, `SharedSubscriptionId`, `MemberIndex`, `Location`, `MgPrefix`, `MemberPrincipalId` (optional), `BudgetAmount`, `BudgetEmail`. It discovers the hub's IDs in the shared subscription by the ALZ-lite names and prints them. Run it after the datacenter exists, so the datacenter is peered too; a re-run after deploying the datacenter adds its peering.
9. The platform lead runs vending for every member, because it writes to the shared subscription (peering and firewall rules). Members need no role on the shared subscription.

### Exemptions

10. `scripts/New-DatacenterExemptions.ps1` finds the policy assignments that `rg-datacenter` violates and creates one exemption per assignment, scoped to `rg-datacenter`: category Waiver, an expiry date parameter (default 14 days from today), and a description with the owner's name, the reason ("pre-existing on-premises simulation, migrating in C7") and the target date. It prints a table that members paste into their deferred-work register.
11. It only exempts `rg-datacenter`. It never exempts the spoke or the workload resources.

### Probes

12. `scripts/Test-Connectivity.ps1` runs checks from inside the datacenter and reports PASS or FAIL per check, then a verdict and exit code:
    - from `vm-dev01` through a VM run command: hub DNS resolves the private DNS zones through the firewall; each private endpoint in `rg-spoke` resolves to a private IP and connects on its port; `10.10.n.4` answers on 80 and 1433; internet egress works through the NAT gateway;
    - from `vm-app01`: the same DNS check and, if a SQL MI exists in the spoke, that its host name resolves to a private IP in `snet-sqlmi` and TCP 5022 and 11000 connect. Use a VM run command, or an Arc run command once the VM is Arc-enabled. 🔎 VERIFY Arc run command support on [Run command on Azure Arc-enabled servers](https://learn.microsoft.com/azure/azure-arc/servers/run-command).
13. It runs only the checks that apply: before the archetype exists, it skips the private endpoint checks and says so.

### Documentation

14. `infra/foundation/README.md`: the two-subscription model (shared services per team, workload per member) with a diagram; the management groups; what ALZ-lite covers compared with a full ALZ (a table of controls); the policy list with definition IDs; the vending inputs; the firewall rule table with the reason for each rule; the UDR table; the permissions the platform lead needs; how exemptions work; and the cost per hour.
15. `versions.md`: rows for the API versions of Azure Firewall, management groups and the policy resources, validated today.

### Validate for real

16. Deploy ALZ-lite with the shared subscription.
17. Deploy the datacenter into the workload subscription with `scripts/Deploy-Datacenter.ps1`, then vending with member index `1`.
18. Run the exemptions script and check that `rg-datacenter` shows as exempt for the assignments it violated.
19. Run `scripts/Test-Connectivity.ps1`: every applicable check passes.
20. Negative tests in the workload subscription, recorded in the PR: creating a storage account with public network access is denied; creating a NIC with a public IP is denied; a private endpoint created without a DNS zone group gets one from the DeployIfNotExists policy within 30 minutes.
21. Tear down (Teardown row). Only delete what this item created: both subscriptions hold other resource groups that must not be touched. Query each kind of artifact and confirm nothing from this item is left, and that both subscriptions are back where requirement 5 of **Before you start** recorded them.

## Deliverables

- `infra/foundation/alz-lite/main.bicep` and `main.bicepparam`, `infra/foundation/vending/main.bicep` and `main.bicepparam`, and their modules.
- `scripts/Deploy-AlzLite.ps1`, `scripts/Deploy-Vending.ps1`, `scripts/New-DatacenterExemptions.ps1`, `scripts/Test-Connectivity.ps1`.
- `infra/foundation/README.md`.
- `versions.md` updated.

## Verify

```powershell
Get-ChildItem infra/foundation -Recurse -Filter main.bicep | ForEach-Object { az bicep lint --file $_.FullName }
Invoke-ScriptAnalyzer -Path scripts -Recurse
az account management-group list --query "[?starts_with(name, 'mg-factory')].name"
npm run check
```

- Lint and PSScriptAnalyzer are clean. After teardown, the management group list is empty.
- The PR body has the deployment times, the probe output, the negative test results, the teardown queries and the cost.

## Done when

- [ ] ALZ-lite creates the management groups, the hub and the workspace in the shared subscription, and enforces the core policies at `mg-factory-corp`.
- [ ] Vending places the workload subscription and connects the spoke and the datacenter to the hub, with UDRs, DNS, firewall rules, RBAC and budget.
- [ ] Exemptions and probes work against live resources.
- [ ] Everything this item created is gone, and both subscriptions are back in their original place.

## Commit message

```text
feat: add ALZ-lite, vending, exemptions and probes
```

## Stop and ask if

- The signed-in user can't create management groups or move subscriptions.
- A built-in policy needed for requirement 4 doesn't exist, or its effect can't be set as listed.
- MI requires routes that conflict with the UDR design in requirement 7.
- Teardown would touch a resource group this item didn't create.

## Notes and traps

- **Existing resources:** the build subscriptions hold other workloads. Policies at `mg-factory-corp` apply to them while the workload subscription is there (deny blocks changes, DeployIfNotExists adds diagnostics). That's why teardown moves the subscriptions back.
- **Moving subscriptions** between management groups can take a few minutes to reflect in policy evaluation. Trigger an evaluation scan before testing.
- **Cross-subscription peering** needs rights on both VNets. The platform lead has them; members don't, which is why the platform lead runs vending.
- **DNS proxy:** VNets that point their DNS at the firewall need the firewall policy's DNS proxy on, or name resolution breaks. Only Standard and Premium support it.
- **Peering order:** set the VNet DNS servers after peering is up, or VMs lose name resolution. Running VMs pick up new DNS servers after a restart or `ipconfig /renew`.
- **Datacenter egress** stays on the NAT gateway: the "on-premises" site doesn't route its internet traffic through Azure.
- **DeployIfNotExists** policies need a managed identity with roles on the zone resource group in the shared subscription, and take time to evaluate.
- **Deny policies and the datacenter:** the datacenter was deployed before the workload subscription moved under `mg-factory-corp`, so it isn't blocked, but it shows as non-compliant until exempted. That's the lesson (PRD §4): deferred work needs an owner, a target and a timeline.
- **SQL MI DNS:** MI isn't reached through a private endpoint here. The app (in the spoke) and MI link (from the datacenter) use the MI's VNet-local endpoint, whose host name Azure DNS resolves to its private IP; the firewall's DNS proxy forwards to Azure DNS. Don't create a `privatelink` zone for it: overriding MI resolution can break its management operations.
