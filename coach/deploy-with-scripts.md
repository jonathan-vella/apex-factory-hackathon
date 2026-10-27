# Deploy with scripts

> [!WARNING]
> Coach material. This is the manual path for repairs. Students deploy from GitHub Actions only and never run these commands by hand.

This page is the coach's repair path. The kit's scripts are the engine the pipeline stages run. Use them when a stage failed twice and can't be repaired in time, when a coach needs to see each step, or when GitHub Actions isn't available. Both paths give the same result, so you can switch between them for different stages. The pipeline itself is described in the [platform pipeline](../facilitator/platform-pipeline.md) page.

There are two roles. **Member** is each member's datacenter. **Team lead** (called the platform lead in the workflow and scripts) also deploys the foundation and vends every member, and is also a member, so the lead's repair covers both. The [readiness gate](readiness.md) and [C2](c02-secure-ai-ready-foundation.md) hold the checks and the hints. This page is the short sequence.

Run every command from `factory/` in the member's dev container, signed in with `az login`. In each new terminal, load the member's settings first:

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
```

## The order matters

The team lead's sequence: T-7 `Deploy-AlzLite.ps1`, then the Graph grant (a person), then T-1 `Deploy-Vending.ps1`, then the VM restarts, the exemptions and the connectivity probes.

Each member's sequence, team lead included: `Test-Preflight.ps1`, `Deploy-Datacenter.ps1`, `Test-Datacenter.ps1`, `Connect-DatacenterArc.ps1`, then a coach approves the readiness record (a person).

Vending needs both ALZ-lite and the member's approved readiness record.

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

The team lead needs Owner at Tenant Root, the shared services subscription in `.local/settings.json`, and the roster values captured for every member.

1. At T-7, deploy the foundation. It takes about 15 to 25 minutes, mostly Azure Firewall, and bills about $1.30 an hour until the event is cleaned up:

   ```powershell
   az account set --subscription $s.sharedSubscriptionId
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -WhatIf
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location
   ```

2. Right after it, a Privileged Role Administrator grants the SQL MI identity its Graph read, once per team, from their own computer and signed in as themselves:

   ```powershell
   ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
   ```

3. The team lead does their own datacenter as a member, above.

4. At T-1, vend each member one after another, after a coach has approved their readiness record. Each run updates the same firewall policy, and takes 4 to 5 minutes:

   ```powershell
   ./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId '<member-subscription-id>' -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <member-index> -MemberPrincipalId '<member-object-id>' -BudgetEmail '<member-email>' -Location $s.location
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

Use the `teardown` stage. By hand, run `Remove-FactoryEnvironment.ps1` for every member scope first, then for the team scope (see [cleanup](../facilitator/cleanup.md)). To stop only the firewall's cost, delete `rg-hub` in the shared services subscription. That leaves the peering to each spoke, the policy assignments, the management groups and the budgets behind.
