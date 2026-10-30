# Cleanup

Run cleanup after the showcase, normally on T+2 (the day after the two-day event). First export and check the evidence; then each member runs the `teardown` stage in their own repo (Member scope); then the team lead runs the `teardown` stage in their repo for the team (Team scope), and an admin runs `Remove-PlatformPipeline.ps1`. Actions is the only student path. The stage runs `Remove-FactoryEnvironment.ps1`, which uses exact kit names and subscription membership under the named kit management groups. It does not delete subscriptions, management groups outside the kit hierarchy or resource groups outside the explicit kit names. The script commands further down are for coaches who repair a failed run.

## Before you delete anything

Member cleanup deletes `rg-datacenter`, which removes `vm-dev01` and its `C:\src\factory` clone. Team cleanup deletes `rg-hub` and the shared policy artifacts. Neither can be undone. Don't start until every item below is true for every member:

- Scores are signed off in the [scoreboard](../coach/scoreboard.md) and no evidence question is open.
- The member's work branch on `vm-dev01` (`vm-dev01-work`, or the branch a coach applied) is pushed to the member's own repo with `git push`. Check `git branch -vv` on `vm-dev01` and that the commits are on GitHub.
- Written evidence is pushed to `main` under `factory/evidence/cNN/`, including the C6 task-check log, C9 fix scripts/results and screenshots, as in [Copy your evidence to your repo](../site/src/content/docs/guides/ghcp-upgrade.md#copy-your-evidence-to-your-repo). The actual C6 task commits stay on the pushed `vm-dev01-work` branch; do not merge it into `main`.
- Each member has noted their `.local/settings.json` values (workload subscription, member index, suffix, location), or the person running cleanup has them. The stage reads the roster and the member index from the repo's settings, but a coach repair needs them by hand, and they're lost if the dev container is rebuilt without the file.
- The event report has the costs and the owner follow-ups.
- The event owner has decided what happens to `id-sqlmi-directory` and its tenant-wide Graph grant (see Post-event access), and a named person has a date to run `Remove-PlatformPipeline.ps1`.
The members' GitHub repos aren't touched by cleanup. Decide with the partner how long to keep them.

## Cleanup from the pipeline

After the event owner's approval, each member runs this in their own repo:

```bash
gh workflow run platform.yml -f stage=teardown
```

The team lead then runs the full cleanup in the lead repo:

```bash
gh workflow run platform.yml -f stage=teardown -f members=all -f confirm-team-teardown=true -f include-management=true
```

Omit only `include-management` if the event owner explicitly reuses the tenant. A one-member repair in the lead repo instead uses `-f members=<index>` and no team confirmation.

The full run removes every roster member first, in parallel, then Team scope once, returning subscriptions to the configured parent. It skips Team scope if a member fails and refuses an unknown subscription under Corp. Each job needs approval where environment reviewers are configured. Without a suffix, Member scope removes all exact `rg-university-<suffix>` groups in that member's subscription. Allow about 20 minutes without an archetype, up to about 2 hours with SQL MI; do not cancel while Azure releases the subnet.

The stage removes only the Owner assignments that vending created: they carry a description that says so. A member's own direct Owner assignment on their workload subscription is left alone.

The workflow never removes its own identity. Each member finalizes their repo (`-Profile Member`); the team lead finalizes the lead repo (default), or the event owner names replacement admins. Each needs repo admin, `gh auth login`, Azure sign-in to the event tenant, and Owner where that pipeline's roles were granted (Tenant Root/configured parent for the lead). Run `Remove-PlatformPipeline.ps1` and verify removal before revoking those human permissions. It removes the pipeline roles, identity, `rg-cicd`, `gh-lab` and its secrets, and repository variables.

## Repair (coaches only): member cleanup by hand

Use this only when a `teardown` run can't be repaired in time. A coach runs Member scope from the `factory/` folder of the member's repo, using the member's workload subscription, member index and archetype suffix, and an account with Owner on that subscription:

```powershell
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Remove-FactoryEnvironment.ps1 -Scope Member -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Suffix $s.suffix -Location $s.location -WhatIf
```

Review the exact resources listed. Run it again without `-WhatIf` to receive the confirmation prompt. Use `-Force` only when the operator has reviewed the plan and is authorized to skip that prompt:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Member -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Suffix $s.suffix -Location $s.location
```

The member scope removes the exact archetype resource group `rg-university-<suffix>`, waits for the SQL MI to release `snet-sqlmi` before removing `rg-spoke`, removes the Arc machine and SQL Server instance for `vm-app01`, deletes the named datacenter and spoke groups, deletes the exact vending budget, and purges only the matching soft-deleted Key Vault.

**An absent member:** after the owner's deadline, the lead's approved full command above includes that roster member. For a single member repair use `-f members=<index>`. Team scope starts only when every member scope succeeds.

## Repair (coaches only): team cleanup by hand

Use this only when the team's `teardown` run can't be repaired in time. After every member scope is complete, the team lead runs the Team scope once, from the `factory/` folder of their own repo, with their `.local/settings.json` (it holds the shared services subscription ID). Members don't run it. Preview it first: it discovers workload subscriptions directly under the kit's Corp group and the shared subscription under its Platform group; no subscription-wide wildcard is used.
Sign in to the event tenant first; the script stops if the active Azure CLI tenant does not match the shared-services subscription.

```powershell
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory -IncludeManagementResources -WhatIf
```

Use the configured prefix instead of `mg-factory` for an event copy. If the owner reuses the tenant, omit `-IncludeManagementResources` in both repair commands. For a return group other than Tenant Root, pass `-ReturnManagementGroupId`. Review the exact subscription/resource list, then run without `-WhatIf` and confirm:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory -IncludeManagementResources
```

Team cleanup removes the named kit policy assignments and datacenter exemptions, vending budgets, kit firewall rule groups and peerings, and policy-created diagnostic role assignments. It also removes the access vending gave each member: Managed Identity Operator on `id-sqlmi-directory`, Reader on the shared services subscription and Owner on the member's workload subscription. It removes only the Owner assignment that vending created, which carries a description saying so; a member's own direct Owner assignment is left alone (vending keeps it as it is, too). It deletes `rg-hub` and the `log-management` workspace. By default it preserves `rg-management`, `id-sqlmi-directory` and that identity's Microsoft Graph grant; `-IncludeManagementResources` deletes them. It then moves the kit subscriptions back and deletes only `<prefix>-corp`, `<prefix>-platform` and `<prefix>`.

## Post-event access

The default keeps `id-sqlmi-directory` and its Graph grant, and the event owner decides. The checklist should delete them unless the tenant is reused for another event. The grant gives `id-sqlmi-directory` the tenant-wide application permissions `User.Read.All`, `GroupMember.Read.All` and `Application.Read.All` in the partner's tenant, and it stays after the event if you keep it. Members hold Managed Identity Operator on it during the event, so they could attach it to other resources and read directory data (see [Accepted lab risks and adopter obligations](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/archetype/README.md#accepted-lab-risks-and-adopter-obligations)). Delete it as soon as the last SQL Managed Instance that uses it is gone. To delete it, run the `teardown` stage with `include-management`, or remove `rg-management` in the shared services subscription once team cleanup has finished; that deletes the identity and its permissions with it (see the header of `scripts/Grant-SqlMiDirectoryRead.ps1`). A later event then needs the grant again. Name the person who does this and the date before the event starts.

Also remove access that was only needed for the event: the team lead's Owner at Tenant Root, the elevated access a Global Administrator used to give it, and any Privileged Role Administrator activation or assignment made for the Graph grant.

## Verify

- Confirm `rg-datacenter`, `rg-spoke` and `rg-university-<suffix>` are absent in each member workload subscription.
- Confirm the Arc machine `vm-app01` and its SQL Server instance are absent; the exact soft-deleted archetype Key Vault has been purged.
- Confirm the shared `rg-hub`, `log-management`, `budget-factory-workload`, `rcg-member-<n>`, `alzl-*` policy assignments and kit exemptions are absent.
- Confirm every workload and shared-services subscription is under the event owner's return management group, and the kit management groups are absent.
- Confirm `rg-management/id-sqlmi-directory` and its Graph grant remain, only if a later event will reuse the tenant. Otherwise confirm they are gone, along with the `rg-management` group. Team cleanup itself removes only the diagnostic policy role assignments and the members' vending-created Managed Identity Operator, Reader and Owner assignments (see Team cleanup).
- Confirm `Remove-PlatformPipeline.ps1` ran in the lead's repo and in each member's repo: `rg-cicd` and `id-factory-pipeline` are gone, its role assignments are gone, the `gh-lab` environment and the `ROSTER_JSON` secret are gone from the repo.
- Confirm no billable kit resources remain. Do not interpret an empty resource-group query alone as proof: check the Arc resources, budgets, policy artifacts and management-group placement too. The challenges create nothing outside the kit's named groups: the Arc assessment is on the Arc SQL Server instance, the C6 image is in the registry in `rg-university-<suffix>`, and the C7 secret is in that group's Key Vault.

If an MI subnet association has not released, the member cleanup stops before deleting the VNet and reports the timeout. Wait for the provider to release the subnet and rerun the same member cleanup; do not force-delete the VNet or manually remove its service association.
