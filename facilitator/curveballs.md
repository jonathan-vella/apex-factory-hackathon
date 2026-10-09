# Curveballs

The coach controls both exercises. Announce the trigger, give teams only the information below, and record the evidence in the normal challenge rubric. Curveballs do not change the B11 base-points contract; eligible bonus evidence still uses the shared 30-point ceiling.

## Day 1: a deny policy lands during the build

**Trigger:** during C2, after ALZ-lite is deployed and before the first archetype resource is provisioned.

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

The parameters and scope are examples for the default `mg-factory` prefix. If the event owner chose another prefix, substitute that prefix; do not use a tenant-specific ID in the assignment. Run the command as the platform lead with permission to assign policy at the management group.

**Team task:** identify the denied deployment and its location, explain why the golden path is compliant, and keep the selected approved region instead of weakening or bypassing the policy. Capture the policy assignment and the resulting decision in the C2 evidence.

**Evidence and points:** the C2 policy evidence is worth 10 team points. Up to 5 C2 bonus points may be awarded for a negative test showing an unapproved region is denied and the approved region remains usable; use the B11 bonus task and the shared bonus cap.

**Reverse after sign-off:** remove only `curveball-allowed-locations` from the same `mg-factory-corp` scope:

```powershell
az policy assignment delete `
  --name curveball-allowed-locations `
  --scope /providers/Microsoft.Management/managementGroups/mg-factory-corp
```

Confirm that the assignment is gone. Do not remove the baseline `alzl-allowed-locations` assignment.

## Day 2: fail the replica go/no-go and abort

**Trigger:** at C7's go/no-go, before cutover. The coach tells the team that the read-only replica check has failed (for example, lag is non-zero, the database is not `READ_ONLY`, or the fingerprints differ). The trigger is an exercise; do not deliberately corrupt the source database.

**Coach action:** do not let the team cut over. Ask them to stop application writes, preserve the source as the authoritative database, and show their abort and recovery plan.

**Team task and safe abort path:**

1. Record the failed check and mark the decision **no-go**. Do not tick “I want to do a forced failover” and do not run `az sql mi link failover --failover-type Planned` from the MI side.
2. In the Arc portal's MI link **Monitor and cutover** pane, select **Cancel migration**. B07 verified that this removes the distributed availability group on both sides without failing over.
3. Confirm that the source is still `READ_WRITE`, has no availability group left and remains the app's target. The MI retains a separate writable database copy after cancellation; it has diverged from the source.
4. Before recreating the link, delete only the MI-side `ContosoUniversity` copy using the supported `az sql midb delete` flow. Verify the copy is gone, then document the reseed and revalidation plan. Do not repoint the app to the standalone MI copy.
5. Re-plan the cutover only after the read-only replica and lag checks pass. For a planned cutover, follow B07's validated Arc portal path. The equivalent T-SQL `ALTER AVAILABILITY GROUP [<DAG>] FAILOVER` runs on SQL Server itself when applicable; it is not the MI-side CLI command above.

**Evidence and points:** retain the failed go/no-go result, the Arc portal cancellation state, the unchanged source check and the MI-copy cleanup/reseed plan. This demonstrates C7's rollback evidence; up to 5 C7 bonus points are available only for a clean reseed-after-abort with evidence. The C7 base evidence is scored under the rubric and no additional base points are created.

**Reverse after sign-off:** if the team recreated a link for the exercise, finish only after a valid replica and go/no-go; otherwise leave the source as the app's target and include the deferred reseed/cutover plan in the handover. The coach must confirm no test-only writable MI copy remains before cleanup.
