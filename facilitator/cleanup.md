# Cleanup

Run cleanup after the showcase, normally on T+2 (the day after the two-day event). First clean each member's resources; then run the team scope once. The team script uses exact kit names and subscription membership under the named kit management groups. It does not delete subscriptions, management groups outside the kit hierarchy or resource groups outside the explicit kit names.

## Member cleanup

From the kit repository, preview each member's cleanup using that member's workload subscription, member index and archetype suffix:

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

After every member scope is complete, preview team cleanup. It discovers workload subscriptions directly under the kit's Corp group and the shared subscription under its Platform group; no subscription-wide wildcard is used.
Sign in to the event tenant first; the script stops if the active Azure CLI tenant does not match the shared-services subscription.

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory -WhatIf
```

If the event owner wants the subscriptions returned to a management group other than Tenant Root, pass its management-group name with `-ReturnManagementGroupId`. Review the exact subscription list and resources, then run without `-WhatIf` and confirm:

```powershell
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix mg-factory
```

Team cleanup removes the named kit policy assignments and datacenter exemptions, vending budgets, kit firewall rule groups and peerings, policy-created diagnostic role assignments and vending's Managed Identity Operator grants. It deletes `rg-hub` and the `log-management` workspace. It preserves `rg-management`, `id-sqlmi-directory` and that identity's Microsoft Graph grant, then moves the kit subscriptions back and deletes only `<prefix>-corp`, `<prefix>-platform` and `<prefix>`.

## Verify

- Confirm `rg-datacenter`, `rg-spoke` and `rg-university-<suffix>` are absent in each member workload subscription.
- Confirm the Arc machine `vm-app01` and its SQL Server instance are absent; the exact soft-deleted archetype Key Vault has been purged.
- Confirm the shared `rg-hub`, `log-management`, `budget-factory-workload`, `rcg-member-<n>`, `alzl-*` policy assignments and kit exemptions are absent.
- Confirm every workload and shared-services subscription is under the event owner's return management group, and the kit management groups are absent.
- Confirm `rg-management/id-sqlmi-directory` and its Graph grant remain. Only vending-created Managed Identity Operator and diagnostic policy role assignments are removed.
- Confirm no billable kit resources remain. Do not interpret an empty resource-group query alone as proof: check the Arc resources, budgets, policy artifacts and management-group placement too.

If an MI subnet association has not released, the member cleanup stops before deleting the VNet and reports the timeout. Wait for the provider to release the subnet and rerun the same member cleanup; do not force-delete the VNet or manually remove its service association.
