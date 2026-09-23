# B02: Prepare the build subscriptions and write the preflight script

| Field | Value |
|---|---|
| Milestone | P1 Skeleton and datacenter |
| Type | Agent |
| Depends on | B00 |
| Unblocks | B04, B08 |
| Effort | 2–3 hours |
| Cost | None |
| Teardown | Not applicable: nothing is deployed |
| PRD | §2 Licensing, Tenancy, Kit build; §5 C0; §8 |

## Outcome

- The two build subscriptions (shared services and workload) are recorded in `.local/settings.json` and ready: the owner has Owner on both and can manage management groups, and the resource providers the kit needs are registered.
- `scripts/Test-Preflight.ps1` gives an attendee a go/no-go answer for C0 (PRD §5). It checks what it can in Azure and lists the rest as manual checks. It runs green against the build subscriptions.

## Before you start

1. `az account show` works. If not, sign in with `az login`.
2. `.local/settings.json` exists with `tenantId`, `sharedSubscriptionId`, `subscriptionId`, `location` and `memberIndex`, which the owner has filled in. If it doesn't, or a key is missing, ask the owner for the values.
3. `Get-Module PSScriptAnalyzer -ListAvailable` returns a module. If not, install it for the current user from the PowerShell Gallery.

## Requirements

### Build subscriptions

1. Check that the two subscriptions in `.local/settings.json` exist in `tenantId` and are different (backlog conventions, **Build environment**). Show their names to the owner in the PR body, not their IDs.
2. Add `suffix` to `.local/settings.json`: 6 random lowercase letters and digits, starting with a letter.
3. Confirm the signed-in user has **Owner** on both subscriptions, directly or inherited, and can create management groups and move subscriptions at the Tenant Root group (B08 needs it). If not, stop and ask.

### Preflight script

4. `scripts/Test-Preflight.ps1` follows the attendee script conventions (PowerShell 7.4, works in Cloud Shell, comment-based help with examples). Parameters:

   | Parameter | Type | Default | Purpose |
   |---|---|---|---|
   | `WorkloadSubscriptionId` | string, mandatory | — | The member's workload subscription |
   | `SharedSubscriptionId` | string | none | The team's shared services subscription. Only the team's platform lead passes it |
   | `Location` | string | `swedencentral` | Target region. `germanywestcentral` is the documented fallback |
   | `Fix` | switch | off | Register missing resource providers instead of only reporting them |
   | `OutFile` | string | none | Also write the results as JSON |

5. Automated checks. Each one reports **PASS**, **FAIL** or **WARN** with a one-line reason and, for FAIL, the fix:

   | Check | PASS when |
   |---|---|
   | PowerShell | 7.4 or later |
   | Azure CLI | 2.70 or later, and signed in |
   | Bicep | 0.30 or later |
   | Tenant | Every subscription passed is in the signed-in tenant |
   | Role: workload | Owner on the workload subscription |
   | Role: shared | Owner on the shared services subscription (only if passed) |
   | Management groups | The signed-in user can create management groups and move subscriptions under Tenant Root (only if `SharedSubscriptionId` is passed). If this can't be determined reliably, report WARN with how to check |
   | Resource providers | Registered on each subscription passed: `Microsoft.Compute`, `Microsoft.Network`, `Microsoft.Storage`, `Microsoft.Sql`, `Microsoft.Web`, `Microsoft.ContainerRegistry`, `Microsoft.ServiceBus`, `Microsoft.KeyVault`, `Microsoft.ManagedIdentity`, `Microsoft.Insights`, `Microsoft.OperationalInsights`, `Microsoft.OperationsManagement`, `Microsoft.HybridCompute`, `Microsoft.GuestConfiguration`, `Microsoft.AzureArcData`, `Microsoft.PolicyInsights`, `Microsoft.Security`, `Microsoft.Management`. With `-Fix`, register the missing ones and wait until they're registered |
   | VM size | `Standard_D8as_v6` is offered in `Location` for the workload subscription without restrictions. WARN, not FAIL, if restricted: the size is a parameter |
   | Region | `Location` exists and offers SQL Managed Instance |

   Don't check quota: that's a deliberate decision (PRD §2 Regions).
6. Manual checks, listed as **MANUAL** with the exact thing to confirm, because they can't be checked reliably from the script:
   - MFA is registered for the account.
   - The account has a GitHub Copilot seat, and the org's Copilot policies allow agent mode, MCP servers and Copilot CLI.
   - The account can create private repos in the partner's GitHub org.
   - APEX can run: Docker Desktop is available, or the account can use Codespaces.
   - The partner holds licences that make Azure Hybrid Benefit eligible, or knows the kit enables AHB by default and how to turn it off.
7. Output: a table of checks, then a one-line verdict: **GO** if nothing failed, otherwise **NO-GO** with the number of failures. Exit code 0 for GO and 1 for NO-GO. Manual checks and warnings don't change the verdict.
8. The script only reads, except for provider registration with `-Fix`. It never creates resources.

### Docs

9. Add a row for PSScriptAnalyzer (the version you ran) to `versions.md`, validated today.

### Run it

10. Run `scripts/Test-Preflight.ps1 -WorkloadSubscriptionId <workload> -SharedSubscriptionId <shared> -Fix` against the build subscriptions. It must end with **GO**. Put the output in the PR body, with IDs replaced by placeholders.
11. Run it once without `-Fix` against a subscription ID that doesn't exist, and check it reports NO-GO with a clear reason, not a stack trace.

## Deliverables

- `scripts/Test-Preflight.ps1`.
- `versions.md` updated.
- `.local/settings.json` updated locally with `suffix`, never committed.

## Verify

```powershell
Invoke-ScriptAnalyzer scripts/Test-Preflight.ps1
Get-Help scripts/Test-Preflight.ps1 -Examples
$s = Get-Content .local/settings.json | ConvertFrom-Json
./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId; $LASTEXITCODE
git status --short --ignored .local
npm run check
```

- PSScriptAnalyzer prints nothing.
- Help shows at least one example.
- The preflight ends with **GO** and exit code `0`.
- `.local/` shows as ignored.

## Done when

- [ ] `.local/settings.json` has the six keys, and the owner has Owner on both subscriptions and the management group rights B08 needs.
- [ ] The preflight script meets requirements 4–8 and runs green on the build subscriptions.
- [ ] The negative test gives NO-GO with a clear reason.
- [ ] `versions.md` is updated.

## Commit message

```text
feat: add the preflight script
```

## Stop and ask if

- The owner doesn't have Owner on both subscriptions, or can't manage management groups.
- A resource provider won't register.
- `Standard_D8as_v6` is restricted in `swedencentral` for the workload subscription: B04 needs it.

## Notes and traps

- **Role checks:** `az role assignment list --assignee` misses roles inherited from groups and management groups. Use `--include-inherited --include-groups`, or check the effective permissions another reliable way.
- **CSP subscriptions:** in a new CSP customer tenant, tenant users often have no role on new subscriptions until the partner (AOBO or GDAP) or a Global Admin who elevates access grants one. The Role FAIL message should say so.
- **Provider registration** can take several minutes. Poll with a timeout rather than failing on the first "Registering" state.
- **SKU restrictions:** `az vm list-skus --location <region> --size Standard_D8as_v6` lists restrictions per subscription. An empty restrictions list means available.
- **Roles at an event:** the platform lead deploys ALZ-lite and runs vending for every member, so only they pass `SharedSubscriptionId`. Members pass only their workload subscription.
