# Curveballs

The coach controls both exercises. Announce the trigger, give teams only the information below, and record the evidence in the normal challenge rubric. Curveballs do not change the base points on the challenge pages; eligible bonus evidence still uses the shared 30-point ceiling.

## Day 1: a deny policy lands during the build

**Trigger:** during C2, after ALZ-lite is deployed and the members are vended, and before the first archetype resource is provisioned.

**Coach action:** assign the built-in Allowed locations policy with Deny effect at the kit's Corp management group. The golden path uses `swedencentral` or the documented `germanywestcentral` fallback, plus `global` where required, so compliant deployments continue. A shortcut that silently selects another region is denied.

```powershell
$parameters = '{"listOfAllowedLocations":{"value":["swedencentral","germanywestcentral","global"]},"effect":{"value":"Deny"}}'
az policy assignment create `
  --name curveball-allowed-locations `
  --display-name "Curveball: deny resources outside the approved regions" `
  --scope /providers/Microsoft.Management/managementGroups/mg-factory-corp `
  --policy /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c `
  --params $parameters
```

The parameters and scope are examples for the default `mg-factory` prefix. If the event owner chose another prefix, substitute that prefix; do not use a tenant-specific ID in the assignment. The platform lead runs the command under the coach's direction, because they hold the rights to assign policy at the management group.

**Team task:** the coach asks the platform lead to try creating any small resource, for example a storage account, in a region outside the approved list (such as westeurope) in a vended subscription. Capture the denial message and its location, explain why the golden path is compliant, and keep the selected approved region instead of weakening or bypassing the policy. Capture the policy assignment and the resulting decision in the C2 evidence.

**Evidence and points:** the denial belongs with the C2 policy evidence, which is worth 10 team points. It earns no bonus on its own. The C2 bonus is the negative tests on the C2 page (a public storage account denied, a NIC with a public IP denied, a private endpoint registering in the central DNS zone), under the shared bonus cap.

**Reverse after sign-off:** remove only `curveball-allowed-locations` from the same `mg-factory-corp` scope:

```powershell
az policy assignment delete `
  --name curveball-allowed-locations `
  --scope /providers/Microsoft.Management/managementGroups/mg-factory-corp
```

Confirm that the assignment is gone. Do not remove the baseline `alzl-allowed-locations` assignment.

## Day 2: fail the replica go/no-go and abort

**Trigger:** at C7's go/no-go, before cutover, for **one member per team** whom the coach picks, so the rest of the team keeps its C7 pace. The coach tells that member that the read-only replica check has failed (for example, lag is non-zero, the database is not `READ_ONLY`, or the fingerprints differ). The trigger is an exercise; do not deliberately corrupt the source database. Cap it at 15 minutes (record, cancel, delete the MI copy, write the plan); the member then restarts the link, and the wait for the new seeding is real, so they use it for the runbook. Because C8 and C9 need the cutover, the member continues with them as soon as their cutover is complete.

**Coach action:** do not let that member cut over. Ask them to stop application writes, preserve the source as the authoritative database, and show their abort and recovery plan.

**Team task and safe abort path:**

1. Record the failed check and mark the decision **no-go**. Do not tick “I want to do a forced failover” and do not run `az sql mi link failover --failover-type Planned` from the MI side.
2. In the Arc portal's MI link **Monitor and cutover** pane, select **Cancel migration**. The [MI link spike](../docs/spikes/B07-arc-mi-link/README.md) verified that this removes the distributed availability group on both sides without failing over.
3. Confirm that the source is still `READ_WRITE`, has no availability group left and remains the app's target. The MI retains a separate writable database copy after cancellation; it has diverged from the source.
4. Before recreating the link, delete only the MI-side `ContosoUniversity` copy using the supported `az sql midb delete` flow. Verify the copy is gone, then document the reseed and revalidation plan. Do not repoint the app to the standalone MI copy.
5. Re-plan the cutover only after the read-only replica and lag checks pass. For a planned cutover, follow the validated Arc portal path in the [MI link spike](../docs/spikes/B07-arc-mi-link/README.md). The equivalent T-SQL `ALTER AVAILABILITY GROUP [<DAG>] FAILOVER` runs on SQL Server itself when applicable; it is not the MI-side CLI command above.

**Evidence and points:** retain the failed go/no-go result, the Arc portal cancellation state, the unchanged source check and the MI-copy cleanup/reseed plan. This demonstrates C7's rollback evidence. The staged abort is part of the event and earns no bonus: the C7 reseed-after-abort bonus (up to 5) is only for a real, unplanned abort. The C7 base evidence is scored under the rubric and no additional base points are created: the rows that need a completed cutover (live pages, contained user) score only if that member finishes the cutover afterwards.

**Reverse after sign-off:** if the team recreated a link for the exercise, finish only after a valid replica and go/no-go; otherwise leave the source as the app's target and include the deferred reseed/cutover plan in the handover. The coach must confirm no test-only writable MI copy remains before cleanup.
