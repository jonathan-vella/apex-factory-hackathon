# B16: Pipeline identity, privilege model and identity-safe scripts

| Field | Value |
|---|---|
| Date | 2026-10-21 |
| Result | ✅ Pass |
| Region | swedencentral |
| Versions | Azure CLI 2.91.0 (local) and the runner's Azure CLI, `azure/login` v3.1.0, PowerShell 7, actionlint 1.7.12 |

Scrubbed: IDs appear as placeholders. The test lab is two empty subscriptions in the build tenant, separate from the live lab.

## Question

Can a GitHub Actions workflow deploy the platform with a managed identity that holds **no role at Tenant Root**, and what does the setup cost a student or coach in effort?

## What we did

1. Added `Initialize-PlatformPipeline.ps1` (one command, idempotent, `-WhatIf`) and `Remove-PlatformPipeline.ps1`.
2. Changed `Deploy-AlzLite.ps1`, `Deploy-Vending.ps1` and `Test-Preflight.ps1` to accept a service principal or managed identity (object ID from the ARM token, no Graph call) and a `-ParentManagementGroupId`.
3. Ran the setup against the test lab with a sandbox parent group, `mg-ci-sandbox`, created under Tenant Root.
4. Ran `platform-smoke.yml` from a `ci-test/*` branch: OIDC login, the identity-safe script checks and `Test-PipelinePermissions.ps1` as the identity, with an approval on the `gh-lab` environment.

## Findings

- **The sandbox design works with no Tenant Root role.** The identity holds Owner on `mg-ci-sandbox` and on the two subscriptions only. As that identity the probe passed: a management-group-scope deployment, creating a child group, moving the workload subscription into it and back, a policy assignment with a system-assigned identity plus its role assignment, and cleanup.
- **Negative test passed.** The identity can't read either live-lab subscription (a denied read is a PASS). This proves resource-plane isolation only: the prefix and the roles are the boundary, not an authorization wall.
- **The OIDC subject isn't always `repo:owner/repo`.** This repo issues immutable subject claims (`repo:owner@<id>/repo@<id>:environment:...`). The first login failed with `AADSTS700213`. The setup script now reads the repo's `actions/oidc/customization/sub` and builds the credential subject from `sub_claim_prefix`. It refuses a repo with a customized claim template.
- **`workflow_dispatch` needs the workflow on the default branch.** Until it is merged, a workflow can't be dispatched from a feature branch (HTTP 404). The smoke workflow also runs on pushes to `ci-test/**`. The trigger can lag by a few minutes, and a run behind another run in the same concurrency group stays pending.
- **`az policy assignment create --policy` wants the bare definition GUID here**, not the full resource ID.
- **A native command that fails on purpose leaks its exit code** from a `pwsh -command` step, so the probe ends with an explicit `exit 0`.
- **Environment gate:** with the owner as required reviewer, a run waits until approved. The gate works on `main`, `feat/*` and `ci-test/*` (the deployment-branch policy).
- **Re-run:** running the setup again changes nothing.
- **Identity-safe scripts pass as the identity.** In the same run `Test-Preflight.ps1` reported GO (the identity's object ID came from its token) and `Deploy-AlzLite.ps1` passed its "Owner at the parent" check. A user sign-in passes the same checks against the same parent.
- **A first-time ALZ-lite `-WhatIf` can't run under a non-root parent.** The what-if has to authorize the nested deployment at `mg-factory-ci-corp`, which doesn't exist yet, so a principal without Tenant Root rights gets `Authorization failed ... Microsoft.Resources/deployments/write`. A user with Owner at Tenant Root doesn't see it. The real deployment creates the group first, so it should not hit this; B17 proves it. After the first deployment the what-if works, because the group exists.

## Decisions

Proposed, pending the owner (none changes the PRD yet):

- Sandbox parent group for the kit's own test lab. At events the lead already holds Owner at Tenant Root, so the default stays Tenant Root.
- Least-privilege Tenant Root roles were not tried, because the sandbox design passed.

## Evidence

- Smoke, identity-safe script checks and probe: workflow run on `ci-test/b16-7`, result success (URL in the PR body). Earlier runs on `b16-1` to `b16-6` found the issues listed above.
- Setup output (scrubbed), `-WhatIf` and live, in the PR body.

## Follow-ups

- B17: the guard, `platform.yml`, `Test-PipelineSetup.ps1` and Import-Kit wiring.
- Arc, exemptions, connectivity and removal under a managed identity are tested in B18 and B19.
- Parallel vending remains untested.
