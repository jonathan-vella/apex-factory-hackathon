# Deploy with scripts (coach)

> [!WARNING]
> Coach material. This is the manual path for repairs. Students deploy from GitHub Actions only and never run these commands by hand.

This page is the coach's repair path, only when an Actions run can't be repaired in time. Rerun or repair the stage first. The kit's scripts are the engine the pipeline stages run, not an alternative attendee deployment path. The pipeline itself is described in the [platform pipeline](../facilitator/platform-pipeline.md) page.

There are two roles. **Member** is each member's datacenter. **Team lead** (called the platform lead in the workflow and scripts) also deploys the foundation and vends every member, and is also a member, so the lead's repair covers both. The [Readiness check](readiness.md) and [C2](c02-secure-ai-ready-foundation.md) hold the checks and the hints. This page is the short sequence.

Run every command from `factory/` in the member's dev container, signed in with `az login`. In each new terminal, load the member's settings first:

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
$mgPrefix = '<MG_PREFIX from the repo gh-lab variables>'
$parentMg = '<PARENT_MG from the repo gh-lab variables>'
```

Read `MG_PREFIX` and `PARENT_MG` in the repository's `gh-lab` environment variables. Set `$parentMg = ''` only when `PARENT_MG` is empty (Tenant Root). Never substitute a guessed scope.

## The order matters

The team lead's sequence: T-7 `Deploy-AlzLite.ps1`, then the Graph grant (a person), then T-1 `Deploy-Vending.ps1`, then the VM restarts, the exemptions and the connectivity probes.

Each member's sequence, team lead included: `Test-Preflight.ps1`, `Deploy-Datacenter.ps1`, `Test-Datacenter.ps1`, `Connect-DatacenterArc.ps1`, then `vm-dev01` setup and readiness evidence commit.

Vending needs both ALZ-lite and each member's Arc-connected datacenter (`Invoke-PipelineVending.ps1` checks `vnet-datacenter` and `vm-app01`'s Arc `Connected` status automatically).

- Run `Test-Datacenter.ps1` **before** Arc: Arc turns off the guest agent the test relies on.
- Never redeploy a datacenter after Arc, and never run the Arc script a second time.
- ALZ-lite and each member's datacenter must exist before vending. The Graph grant comes after ALZ-lite and before C7.

## Member

The deploy takes up to 60 minutes, unattended. Keep the terminal open and the computer awake.

1. Check the subscription. Fix every FAIL, then re-run with `-Fix` to register providers:

   ```powershell
   ./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -Location $s.location -OutFile .local/preflight.json
   ```

2. Deploy the datacenter. It is safe to run again until Arc onboarding. For a member without eligible Windows Server licenses, add `-NoHybridBenefit`:

   ```powershell
   ./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   For an event copy, also pass `-Repository '<event-owner/event-repo>' -ScriptsRef '<reviewed-commit-or-tag>'` so the guest scripts come from the same reviewed copy. Outside a disposable lab, collect secure strings with `Read-Host -AsSecureString` and pass `-AdminPassword $adminPassword -SqlAppPassword $sqlAppPassword`; never put passwords in a command, log or repo. Preserve the deployment's original credentials on a repair.

3. Confirm it is healthy. Every row must be PASS. Save the output as the evidence (add `-NoHybridBenefit` for a member without eligible licenses, or the license row fails):

   ```powershell
   ./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
   ```

4. Onboard `vm-app01` to Azure Arc. Don't run it again if it times out after it started:

   ```powershell
   ./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

5. The member does the steps only a person can: the Arc migration assessment in the portal and the `vm-dev01` setup. A hand-run deploy writes `.local/<subscription-id>/datacenter.json` itself, so `Get-PipelineEvidence.ps1` isn't needed.

## Team lead

The team lead needs Owner at the configured parent management group (Tenant Root when no parent is set), access to the shared services subscription in `.local/settings.json`, and the roster values captured for every member.

1. At T-7, deploy the foundation. It takes about 15 to 25 minutes, mostly Azure Firewall, and bills about $1.30 an hour until the event is cleaned up:

   ```powershell
   az account set --subscription $s.sharedSubscriptionId
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -MgPrefix $mgPrefix -ParentManagementGroupId $parentMg -WhatIf
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -MgPrefix $mgPrefix -ParentManagementGroupId $parentMg
   ```

2. Right after it, a Privileged Role Administrator grants the SQL MI identity its Graph read, once per team, from their own computer and signed in as themselves:

   ```powershell
   ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
   ```

3. The team lead does their own datacenter as a member, above.

4. At T-1, vend each member one after another, after confirming their Step 3 datacenter and Arc connection are complete. Each run updates the same firewall policy, and takes 4 to 5 minutes:

   ```powershell
   ./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId '<member-subscription-id>' -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <member-index> -MemberPrincipalId '<member-object-id>' -BudgetEmail '<member-email>' -Location $s.location -MgPrefix $mgPrefix -ParentManagementGroupId $parentMg
   ```

5. For every member, restart both VMs, record the exemptions, then run the probes. Tell the member first: a restart ends their Bastion session.

   ```powershell
   az vm restart -g rg-datacenter -n vm-dev01 --subscription '<member-subscription-id>'
   az vm restart -g rg-datacenter -n vm-app01 --subscription '<member-subscription-id>'
   ./scripts/New-DatacenterExemptions.ps1 -SubscriptionId '<member-subscription-id>' -Owner '<member name>'
   ./scripts/Test-Connectivity.ps1 -SubscriptionId '<member-subscription-id>' -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <member-index>
   ```

   If the exemptions output says "nothing to do", the policies haven't taken effect yet (up to 30 minutes after ALZ-lite). Wait and run it again.

Never commit the member values (subscription ID, object ID, email) to any repo. The team lead takes them from the private roster.

## If something breaks

The scripts are idempotent. Run the same command again to converge a failed or partial deployment. There is no `-Force` parameter. If a member's datacenter is redeployed before Arc, the team lead vends that member again, restarts both VMs and records the exemptions again.

## Taking it down

Use the `teardown` stage. By hand, run `Remove-FactoryEnvironment.ps1` for every member scope first, then for the team scope (see [cleanup](../facilitator/cleanup.md)). Deleting `rg-hub` stops the firewall's cost but also breaks central DNS and connectivity for every vended spoke; it is not a pause switch. Recovery requires redeploying the foundation and rerunning vending for every member. Peerings, policy assignments, management groups and budgets can remain behind.
