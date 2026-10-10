# Cleanup

Run cleanup after the showcase, normally on T+2 (the day after the two-day event). First export and check the evidence; then each member cleans their own resources (Member scope); then the platform lead runs the Team scope once. The team script uses exact kit names and subscription membership under the named kit management groups. It does not delete subscriptions, management groups outside the kit hierarchy or resource groups outside the explicit kit names.

## Before you delete anything

Member cleanup deletes `rg-datacenter`, which removes `vm-dev01` and its `C:\src\factory` clone. Team cleanup deletes `rg-hub` and the shared policy artifacts. Neither can be undone. Don't start until every item below is true for every member:

- Scores are signed off in the [scoreboard](scoreboard.md) and no evidence question is open.
- The member's work branch on `vm-dev01` (`vm-dev01-work`, or the lifeline branch a coach applied) is pushed to the member's own repo with `git push`. Check `git branch -vv` on `vm-dev01` and that the commits are on GitHub.
- The evidence that the challenge pages ask for is in the team repo under `evidence/cNN/member-<n>/`, copied, committed and pushed as in [Copy your evidence to the team repo](../site/src/content/docs/guides/ghcp-upgrade.md#copy-your-evidence-to-the-team-repo). That covers the C6 task commits, the C9 fix scripts and results, and any screenshots from the Azure portal or Application Insights.
- Each member has noted their `.local/settings.json` values (workload subscription, member index, suffix, location), or the person running cleanup has them. Member cleanup needs them, and they're lost if the dev container is rebuilt without the file.
- The event report has the costs and the owner follow-ups.

The GitHub repos (members' repos and the team repo) aren't touched by cleanup. Decide with the partner how long to keep them.

## Member cleanup

Each member runs Member scope from the `factory/` folder of their own repo, in their own dev container, using their own workload subscription, member index and archetype suffix. If the event owner runs it for a member, use the values that member noted and an account with Owner on their subscription:

```powershell
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Remove-FactoryEnvironment.ps1 -Scope Member -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Suffix $s.suffix -Location $s.location -WhatIf
```

Review the exact resources listed. Run it again without `-WhatIf` to receive the confirmation prompt. Use `-Force` only when the operator has reviewed the plan and is authorized to skip that prompt:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Member -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Suffix $s.suffix -Location $s.location
```

The member scope removes the exact archetype resource group `rg-university-<suffix>`, waits for the SQL MI to release `snet-sqlmi` before removing `rg-spoke`, removes the Arc machine and SQL Server instance for `vm-app01`, deletes the named datacenter and spoke groups, deletes the exact vending budget, and purges only the matching soft-deleted Key Vault.

## Team cleanup

After every member scope is complete, the platform lead runs the Team scope once, from the `factory/` folder of their own repo, with their `.local/settings.json` (it holds the shared services subscription ID). Members don't run it. Preview it first: it discovers workload subscriptions directly under the kit's Corp group and the shared subscription under its Platform group; no subscription-wide wildcard is used.
Sign in to the event tenant first; the script stops if the active Azure CLI tenant does not match the shared-services subscription.

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory -WhatIf
```

If the event owner wants the subscriptions returned to a management group other than Tenant Root, pass its management-group name with `-ReturnManagementGroupId`. Review the exact subscription list and resources, then run without `-WhatIf` and confirm:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory
```

Team cleanup removes the named kit policy assignments and datacenter exemptions, vending budgets, kit firewall rule groups and peerings, policy-created diagnostic role assignments and vending's Managed Identity Operator grants. It deletes `rg-hub` and the `log-management` workspace. It preserves `rg-management`, `id-sqlmi-directory` and that identity's Microsoft Graph grant, then moves the kit subscriptions back and deletes only `<prefix>-corp`, `<prefix>-platform` and `<prefix>`.

## Post-event access

Preserving the identity is opt-out, not a requirement. The grant gives `id-sqlmi-directory` the tenant-wide application permissions `User.Read.All`, `GroupMember.Read.All` and `Application.Read.All` in the partner's tenant, and it stays after the event. If no later event will reuse the tenant, delete `rg-management` in the shared services subscription once team cleanup has finished; that deletes the identity and its permissions with it (see the header of `scripts/Grant-SqlMiDirectoryRead.ps1`). A later event then needs the grant again.

Also remove access that was only needed for the event: the platform lead's Owner at Tenant Root, the elevated access a Global Administrator used to give it, and any Privileged Role Administrator activation or assignment made for the Graph grant.

## Verify

- Confirm `rg-datacenter`, `rg-spoke` and `rg-university-<suffix>` are absent in each member workload subscription.
- Confirm the Arc machine `vm-app01` and its SQL Server instance are absent; the exact soft-deleted archetype Key Vault has been purged.
- Confirm the shared `rg-hub`, `log-management`, `budget-factory-workload`, `rcg-member-<n>`, `alzl-*` policy assignments and kit exemptions are absent.
- Confirm every workload and shared-services subscription is under the event owner's return management group, and the kit management groups are absent.
- Confirm `rg-management/id-sqlmi-directory` and its Graph grant remain. Only vending-created Managed Identity Operator and diagnostic policy role assignments are removed.
- Confirm no billable kit resources remain. Do not interpret an empty resource-group query alone as proof: check the Arc resources, budgets, policy artifacts and management-group placement too. The challenges create nothing outside the kit's named groups: the Arc assessment is on the Arc SQL Server instance, the C6 image is in the registry in `rg-university-<suffix>`, and the C7 secret is in that group's Key Vault.

If an MI subnet association has not released, the member cleanup stops before deleting the VNet and reports the timeout. Wait for the provider to release the subnet and rerun the same member cleanup; do not force-delete the VNet or manually remove its service association.
