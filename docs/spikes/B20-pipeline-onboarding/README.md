# B20: Platform pipeline onboarding test and azd decision

| Field | Value |
|---|---|
| Date | 2026-10-22 to 2026-10-23 |
| Result | ✅ Pass, with fixes found and made |
| Region | swedencentral |
| Versions | Azure CLI on the hosted runner and 2.91.x locally, `azure/login` v3, `actions/checkout` v7, `actions/upload-artifact` v7, PowerShell 7.4+, actionlint 1.7.12 |

Scrubbed: IDs appear as placeholders. The test lab is three subscriptions in the build tenant, separate from the live lab. Both test repos were throwaway private repos on a free GitHub plan, created from the `apex-accelerator` template, with the kit imported by `Import-Kit.ps1`.

## Question

Can a new student or platform lead get from an imported repo to a green run using only the docs, and is an azd wrapper worth adding?

## What we did

1. **Member (B21).** Throwaway private repo, a never-used subscription, `Initialize-PlatformPipeline.ps1 -Profile Member`, then `whatif` and `member`, then `Get-PipelineEvidence.ps1`.
2. **Platform lead.** A second throwaway private repo, settings with a shared services subscription and a two-member roster, `Initialize-PlatformPipeline.ps1 -RosterPath <roster>`, then `whatif`, `foundation` and `teardown`. A sandbox parent management group stood in for Tenant Root, so the identity held no Tenant Root role. The lead's `member` and `vending` stages were proved earlier in the kit's own test lab.
3. Each lab was removed with the pipeline's `teardown` stage and then the finalizer, and checked with queries.

## Findings

- **Member profile worked first time with defaults.** Setup passed, preflight registered the providers and the public IP feature on a new subscription in about 2 minutes, the datacenter deployed in 35 minutes in total, 46 of 46 checks passed, Arc connected, the evidence downloaded. The identity held Owner on that one subscription. With no reviewer option on the free plan, write access was the gate and setup said so.
- **A real bug, found only by the lead test.** In `Initialize-PlatformPipeline.ps1` an `if` expression that returned `@($x)` unrolled to a string, so `+=` joined the scopes into one string and no role was granted at the parent or the subscriptions. The doctor reported `The identity lacks Owner at 4 of 4 scope(s)`. The member path was not affected. Fixed in the member profile PR.
- **A transient management group failure.** The first `foundation` run failed with `AuthorizationFailed` on `managementGroups/read` for a group it had just created under the sandbox, minutes after the role was granted. A re-run succeeded in 10 minutes. `Deploy-AlzLite.ps1` now retries the group creation up to five times, 30 seconds apart.
- **Teardown without a reviewer gate** ran both jobs with no approval, as intended for a private free-plan repo.
- **`teardown` leaves `rg-management` on purpose.** The lead test removed it by hand afterwards. `include-management` removes it in the pipeline.
- **Stumbles to know about:**
  - `Initialize-Settings.ps1` has an optional prompt for the shared subscription, so a scripted run needs an Enter on stdin.
  - A standalone `Test-PipelineSetup.ps1` in a sandbox lab needs `-ParentManagementGroupId`, or it checks Tenant Root and reports a failure. An event lab uses Tenant Root and doesn't hit this.
  - The next-step text said to approve in the Actions tab even with no gate. It now says "if GitHub asks".

## azd decision: no-go

**No-go for an azd wrapper.** Reasons:

1. **azd can't do the platform.** `azd provision` supports subscription and resource-group scope. ALZ-lite and vending deploy at management-group scope, so azd can't run them at all.
2. **The datacenter script does more than provision.** `Deploy-Datacenter.ps1` also writes the settings, hands credentials to the VMs and downloads the VM scripts from the kit at a pinned ref, and the pipeline then runs `Test-Datacenter` before Arc. An azd wrapper would call the script or reimplement it.
3. **A second state to explain.** azd keeps its own environment folder and sign-in. A student would learn one more tool, and a coach one more thing to debug, for no gain over `Initialize-PlatformPipeline.ps1` plus a workflow.
4. **The archetype already uses azd** (C5). That is where it fits, and nothing here changes it.

This decision comes from the scope limits and from reading the scripts. We didn't prototype a wrapper. Revisit it if azd gains management-group scope.

## Tested and not tested

Tested: the member profile from a fresh private repo, the lead setup, `whatif`, `foundation` and `teardown` from a fresh private repo, the finalizer for both profiles, and the check queries after each teardown.

Not tested: parallel vending (it is serial by design), a required-reviewer gate in a private repo, Tenant Root Owner on a real event tenant, and more than two members.

## Follow-ups

- At the first event, record the real time and Actions minutes of each stage.
