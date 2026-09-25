# B07: Spike: Arc onboarding and MI link migration

| Field | Value |
|---|---|
| Milestone | P2 Spikes |
| Type | Both |
| Depends on | B05, B06 |
| Unblocks | B08, B09, B11 |
| Effort | 2–3 days elapsed, mostly waiting for MI provisioning and seeding |
| Cost | SQL MI free offer: no compute or storage charge within the free limits (🔎 VERIFY on [SQL MI free offer](https://learn.microsoft.com/azure/azure-sql/managed-instance/free-offer)). Arc-enabled SQL Server Developer: free. Plus the datacenter at about $1.55/hour |
| Teardown | Delete `rg-spike-b07` and **`rg-datacenter`** at the end. This item closes the datacenter chain started in B04 |
| PRD | §5 C0, C3, C7; §6 Datacenter, Migration; §8 Arc and MI link risks |

## Outcome

- `vm-app01` can be onboarded to Azure Arc in two ways: the portal way (documented path) and an unattended kit script (fallback). SQL Server shows up as an Arc-enabled SQL Server, and the Arc SQL migration assessment runs.
- The `ContosoUniversity` database migrates online to a SQL MI free offer through the Arc portal migration with MI link: link created, seeded, read-only replica validated, planned cutover, link removed.
- The report records the network and certificate requirements, timings, the abort path for the Day 2 curveball, the failback result and how `licenseType` behaves on the free offer. B08, B09 and B11 build on it.

## Before you start

1. B05 and B06 are closed. `scripts/Test-Datacenter.ps1` passes, including the perf kit checks.
2. The workload subscription has no SQL MI free offer in use: `az sql mi list --query "[].{name:name, pricingModel:pricingModel}"` shows none with the free offer. Only one is allowed per subscription.
3. `.local/settings.json` has `subscriptionId`, `location`, `memberIndex` and `suffix`.

## Requirements

### Arc prerequisites on the VM

1. Azure VMs can't be Arc-enabled as they are. Use the Jumpstart pattern for Azure VMs, **before** the Connected Machine agent is installed: remove the VM extensions, set `MSFT_ARC_TEST`, turn off the Azure guest agent, and block both Azure IMDS addresses (`169.254.169.254` and `169.254.169.253`). 🔎 VERIFY the current steps and order on [Evaluate Arc-enabled servers on an Azure VM](https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine).
2. The datacenter deployment places a prep script at `C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1` on `vm-app01`, but doesn't run it. Change B04's in-VM scripts for this. The script applies requirement 1, is idempotent and tells the user that run commands and VM extensions stop working after it.
3. The datacenter running since B04 doesn't have the script yet. Re-run `scripts/Deploy-Datacenter.ps1 -ScriptsRef <this branch>` so it converges, and check the file exists on `vm-app01`, before either onboarding path. After the prep script runs, run commands stop working, so this must happen first.

### Onboarding: portal way

4. `docs/spikes/B07-arc-mi-link/onboarding-portal.md`: the attendee steps. Connect to `vm-app01` through Bastion, run the prep script, generate the onboarding script in the portal (**Azure Arc → Machines → Add**, single server, interactive sign-in, resource group `rg-datacenter`, region `location`), run it, then confirm SQL Server appears under **Azure Arc → SQL Server instances**. These steps become C0 content in B11.
5. 🧑 HUMAN: the owner follows the steps once and times them.

### Onboarding: kit script

6. `scripts/Connect-DatacenterArc.ps1` (attendee script conventions) onboards `vm-app01` unattended from Cloud Shell or the owner's machine, using the signed-in user's token (no service principal). Parameters: `SubscriptionId`, `MemberIndex`, `Location`.
7. Turning off the guest agent ends any run command, so the script uses one run command only to stage the work and return: it copies the token (as a protected parameter) and registers a one-time scheduled task that starts a minute later. The task runs the prep script (requirement 1), then installs the Connected Machine agent and connects it with the token, and logs to `C:\LabTools\logs`.
8. It waits until the Arc machine is **Connected** and the SQL Server extension has reported the instance, then prints the next steps (the migration assessment). If the machine doesn't connect within 20 minutes, it says where the log is and how to reach it through Bastion.
9. It refuses to run if the machine is already Arc-connected, and says how to check.
10. To test both ways, onboard with one, then redeploy the datacenter (Arc changes can't be undone reliably) and onboard with the other. Record both timings.

### Arc SQL

11. The Arc-enabled SQL Server shows edition Developer and a licence type that isn't billed. Record the licence type the extension set.
12. Run the Arc SQL migration assessment for `ContosoUniversity` from the portal. Save the result (scrubbed) in the spike folder and record how long it took to become available after onboarding.

### Target MI

13. `docs/spikes/B07-arc-mi-link/infra/main.bicep` deploys into `rg-spike-b07`:
    - `vnet-spike-mi` `10.20.n.0/24` with `snet-sqlmi` `10.20.n.128/26`, delegated to `Microsoft.Sql/managedInstances`, with the NSG and route table MI requires;
    - peering both ways with `vnet-datacenter`;
    - a General Purpose SQL MI on the **free offer**, named `sqlmi-university-<suffix>-b07`: 4 vCores, Standard-series hardware, 64 GB storage (🔎 VERIFY the free-offer property and limits); database format (update policy) **SQL Server 2022**; Entra-only authentication with the owner as admin; public endpoint off; zone redundancy off; time zone `W. Europe Standard Time`.
14. Try `licenseType: 'BasePrice'` on the free offer. Record whether it's accepted and whether it changes billing. B09 uses the result.
15. Record the provisioning time.

### Network for MI link

16. Open exactly what MI link needs between `vm-app01` and the MI subnet, in each direction, and nothing more: 🔎 VERIFY the ports and directions on [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation) (at the time of writing: 5022 both ways, and 11000–11999 from the SQL Server to the MI). Apply them in the NSGs (`nsg-servers` and the MI subnet's NSG) and in Windows Firewall on `vm-app01`. Record the rules for B08, which moves them to the hub firewall.
17. Test connectivity **in both directions** before creating the link, with the methods the same page documents (for example the SSMS network checker, or its T-SQL and SQL Agent tests from each side), not only from `vm-app01`. A one-way test can pass while the MI can't reach the SQL Server.

### Migrate with MI link

18. Prepare the source database as MI link needs (full recovery model, a full backup, a database master key) and record each step.
19. 🧑 HUMAN: the owner creates the link from the Arc portal migration experience (**Arc-enabled SQL Server → Migration → Migrate to SQL MI with MI link**), following `docs/spikes/B07-arc-mi-link/migration.md`, which you write before this step. Record where the portal's steps differ from the doc, and fix the doc.
20. Record the seeding time and the database size.
21. Validate the read-only replica: connect with the Entra admin from `vm-dev01` (SSMS or `sqlcmd`), check row counts against the source, and check the compatibility level is still `110` and the perf kit objects exist.
22. **Abort path (Day 2 curveball):** before cutting over, delete the link without failing over, confirm the source is untouched and the app still works, then recreate the link and let it reseed. Record the steps and timings.
23. **Cutover:** do a planned failover that removes the link. Confirm the MI database is read-write. Run `db/perf-kit/Start-Workload.ps1 -Authentication ActiveDirectoryDefault` against the MI for 5 minutes as a smoke test.
24. **Failback (bonus):** try a failback to the source with a new link. Record whether it works on the free offer with the SQL Server 2022 update policy, and the steps. If it doesn't work, record why and move on.
25. **LRS:** if MI link can't seed or cut over on the free offer after two attempts, stop and ask whether to test Log Replay Service instead (PRD §6, LRS fallback).

### Report

26. `docs/spikes/B07-arc-mi-link/README.md` follows the spike report format and covers: both onboarding ways with timings; the Arc SQL licence type and assessment; MI provisioning, seeding, abort, cutover and failback timings; the exact network rules; certificate handling (what the portal does for you); the `licenseType` result; the Day 2 schedule implications (when to start the link so seeding overlaps C6); and follow-ups for B08 (firewall rules through the hub), B09 (MI settings) and B11 (C0 and C7 content).

### Teardown

27. Delete `rg-spike-b07` (the MI and its virtual cluster can take a while; wait until the subnet is free) and `rg-datacenter`, including the Arc resources in it. Confirm both groups are gone and no Arc machine or role assignment from this item is left.

## Deliverables

- `scripts/Connect-DatacenterArc.ps1`.
- The prep script under `infra/datacenter/scripts/`, placed on `vm-app01` by the datacenter deployment.
- `docs/spikes/B07-arc-mi-link/README.md`, `onboarding-portal.md`, `migration.md`, `infra/main.bicep`, and scrubbed evidence.
- `versions.md` rows for the Connected Machine agent, the Arc SQL extension and the MI database format, validated today.

## Verify

```powershell
Invoke-ScriptAnalyzer -Path scripts/Connect-DatacenterArc.ps1, infra/datacenter/scripts -Recurse
az bicep lint --file docs/spikes/B07-arc-mi-link/infra/main.bicep
az group exists -n rg-spike-b07
az group exists -n rg-datacenter
npm run check
```

- Static checks are clean. Both `az group exists` print `false` after teardown.
- The PR body has the timings table, the `licenseType` result and the total cost of the datacenter chain B04–B07.

## Done when

- [ ] Both onboarding ways work and are documented.
- [ ] The database migrated online with MI link, including the abort path and a planned cutover.
- [ ] The failback and `licenseType` results are recorded.
- [ ] The report gives B08, B09 and B11 what they need.
- [ ] `rg-spike-b07` and `rg-datacenter` are deleted.

## Commit message

```text
docs: add the B07 Arc and MI link spike report
```

## Stop and ask if

- Arc onboarding on the Azure VM fails with the Jumpstart pattern.
- The subscription already has a free-offer MI.
- The Arc portal doesn't offer MI link migration for this instance.
- MI link fails twice (requirement 25).

## Notes and traps

- **Order matters:** once the prep script runs, run commands and extensions stop working on `vm-app01`. Anything else that needs a run command must happen first.
- **One free MI per subscription.** B09 deploys the archetype's MI in the same workload subscription, so this item's MI must be deleted first.
- **Free-offer credits:** the free offer includes a monthly pool of vCore hours, and a 4-vCore MI uses them four times faster than wall-clock time. An MI with an active link can't be stopped. Record how many credits B07 used, so B09 and B10 can plan theirs.
- **An MI with an active link can't be stopped,** so the free offer's stop schedule only applies after cutover.
- **The replica is read-only** until cutover. Database users for app identities can only be created afterwards (PRD §6).
- **Arc resource location:** put the Arc machine in `rg-datacenter`, so it's cleaned up with the datacenter and matches the attendee setup.
- **Deleting the MI** releases the subnet only after its virtual cluster is removed, which can take an hour or more. Don't delete the VNet before that.
