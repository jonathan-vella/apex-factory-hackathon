# B16: Spike: pipeline identity, privilege model and identity-safe scripts

| Field      | Value                                                                                                    |
| ---------- | -------------------------------------------------------------------------------------------------------- |
| Issue      | #124                                                                                                     |
| Milestone  | P6 Platform automation                                                                                   |
| Type       | Both                                                                                                     |
| Depends on | — (written as post-v1 with the v1 kit unchanged; superseded: B22 later re-sequenced the event) |
| Unblocks   | B17                                                                                                      |
| Effort     | 3–5 days elapsed, including the owner's admin steps                                                      |
| Cost       | Under $1 for the identity and the empty management groups; the permission probe deploys nothing billable |
| Teardown   | Keep the identity, sandbox group and `gh-lab` environment for B17 to B19. B19 removes them               |
| PRD        | §2 Platform pipeline; §6 Platform pipeline; §8 pipeline identity risk                                    |

## Outcome

- `scripts/Initialize-PlatformPipeline.ps1` sets up the pipeline's identity and GitHub environment in one command. `scripts/Remove-PlatformPipeline.ps1` undoes it.
- `Deploy-AlzLite.ps1`, `Deploy-Vending.ps1` and `Test-Preflight.ps1` work when signed in as a managed identity, not only as a user.
- A report in `docs/spikes/B16-pipeline-identity/README.md` states which role set is enough, with evidence.

## Before you start

1. Read `docs/adapt-skill-and-actions.md` and the #96 research summary in the issue.
2. `.local/ci-lab.json` names the test lab: two empty subscriptions in the build tenant, the prefix `mg-factory-ci` and the sandbox group `mg-ci-sandbox`. Never touch the live lab in `.local/settings.json`.
3. `gh auth status` shows an account with admin on this repo.

## Requirements

### Setup script

1. `Initialize-PlatformPipeline.ps1` follows the script conventions in the [README](README.md#scripts). It reads `.local/settings.json` (or `-SettingsPath`) and the repo from the git remote, prompts only for what is missing, and is idempotent: a re-run converges. `-WhatIf` prints exactly what it would create or grant.
2. Parameters include `-ParentManagementGroupId` (default: Tenant Root, for events). With a sandbox group it grants the identity Owner on that group and on the workload and shared subscriptions only, never at Tenant Root.
3. It creates, in the shared subscription, resource group `rg-cicd` and the user-assigned managed identity `id-factory-pipeline`. It adds one federated credential whose subject is `repo:<owner>/<repo>:environment:<environment>` (no wildcards), and polls until the credential works, so the user never sees `AADSTS70021`.
4. GitHub side, signed in with `gh` as a repo admin, in this order: create environment `gh-lab` with a deployment-branch policy and the owner as required reviewer; set the variables `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `SHARED_SUBSCRIPTION_ID`, `LOCATION`, `MG_PREFIX`, `PARENT_MG`, `ALLOWED_SUBSCRIPTIONS`; set the secret `ROSTER_JSON`. If the repo's plan can't have required reviewers (private repo on a free plan), say so, fall back to write access as the gate and record it. Verify the final GitHub state instead of assuming the calls worked.
5. A built-in smoke test logs in with the identity through a small workflow run and prints the result and the next command.
6. `Remove-PlatformPipeline.ps1` removes the role assignments, the credential, the identity, `rg-cicd` and the environment, then verifies each is gone with a query. It is run by a separate, signed-in admin.

### Identity-safe scripts

7. In `Deploy-AlzLite.ps1`, `Deploy-Vending.ps1` and `Test-Preflight.ps1`, replace `az ad signed-in-user show` with a function that returns the caller's object ID from the ARM token's `oid` claim when the account is a service principal or managed identity. No Microsoft Graph call.
8. Replace the "Owner at Tenant Root" check with "sufficient rights at the parent": Owner at the deployment parent group (Tenant Root or `-ParentManagementGroupId`). Both scripts accept `-ParentManagementGroupId`. The error messages stay as helpful as they are now. Behaviour for a signed-in user at Tenant Root doesn't change.

### Permission probe

9. 🧑 HUMAN: the owner confirms the admin steps the script can't do for itself (create `mg-ci-sandbox`, move the two subscriptions into it).
10. Run a probe as the identity that exercises: a management-group-scope deployment, child management group creation, subscription placement, a policy assignment with a system-assigned identity and its role assignments, and cleanup. Record which roles were needed. Try the least-privilege Tenant Root options only if the sandbox design fails, and ask the owner first.
11. Negative test: the identity can't read or write the live-lab subscriptions (read attempts only).

## Deliverables

- `scripts/Initialize-PlatformPipeline.ps1`, `scripts/Remove-PlatformPipeline.ps1`.
- Changes to `scripts/Deploy-AlzLite.ps1`, `scripts/Deploy-Vending.ps1`, `scripts/Test-Preflight.ps1`.
- `docs/spikes/B16-pipeline-identity/README.md` (report format in the [README](README.md#spike-reports)), `versions.md` rows for the actions and tools used.

## Verify

- PSScriptAnalyzer is clean on every changed script. `npm run check` passes.
- A user sign-in still passes the three scripts' checks (`-WhatIf` against the test lab).
- The probe and negative test results are in the report, scrubbed of IDs.

## Done when

- [ ] One command creates the identity and environment, and a re-run changes nothing.
- [ ] The probe states which roles are enough.
- [ ] The negative test passes.

## Commit message

```text
feat: add the platform pipeline identity setup and identity-safe scripts
```

## Stop and ask if

- The sandbox design fails and a Tenant Root role would be needed.
- A policy denies the probe.
- The identity can read the live lab.

## Notes and traps

- A same-tenant prefix isn't an authorization boundary. The guard in B17 and the roles are the controls.
- Don't print IDs. Use `<subscription-id>` placeholders in the report.
- Federated credentials take minutes to propagate; poll, don't sleep.
- The OIDC subject can be immutable (`repo:owner@<id>/repo@<id>:environment:...`): read it from `actions/oidc/customization/sub`, never assume `repo:owner/repo`.
- `workflow_dispatch` only works for a workflow on the default branch. Until the merge, run the smoke workflow by pushing a `ci-test/*` branch.
