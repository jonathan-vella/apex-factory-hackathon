# B17: Build the entry workflow, guard, onboarding and the what-if and foundation stages

| Field      | Value                                                                  |
| ---------- | ---------------------------------------------------------------------- |
| Issue      | #125                                                                   |
| Milestone  | P6 Platform automation                                                 |
| Type       | Both                                                                   |
| Depends on | B16                                                                    |
| Unblocks   | B18                                                                    |
| Effort     | 3–5 days elapsed                                                       |
| Cost       | About $1.30/hour while the foundation exists (Azure Firewall Standard) |
| Teardown   | Keep the foundation for B18. B19 removes it                            |
| PRD        | §6 Platform pipeline                                                   |

## Outcome

- `platform.yml` runs the platform from Actions with a `stage` choice, and the what-if and foundation stages work in the test lab.
- A guard step fails closed on a wrong subscription or prefix.
- A student or coach can onboard with one command and check it with a doctor script.

## Before you start

1. B16 is closed (issue #124). The identity, `gh-lab` and the sandbox group exist.
2. Read `.github/workflows/` for the pinning and permissions style the repo already uses.

## Requirements

1. `.github/actions/guard/action.yml`: a composite step that fails closed unless every subscription ID is in `ALLOWED_SUBSCRIPTIONS`, none is on the live-lab deny list, and `MG_PREFIX` matches the allowed pattern. It runs first in every job.
2. `platform.yml` (`workflow_dispatch`) has a `stage` input: `whatif`, `foundation`, `member`, `vending`, `all`, `teardown`, plus a `members` input of non-sensitive indexes (default `[1]`). It calls reusable workflows (`platform-whatif.yml`, `platform-foundation.yml`; B18 and B19 add the rest). Member details come from `ROSTER_JSON` inside the gated job, because `secrets` can't be used in `strategy`.
3. Jobs use `azure/login` with OIDC (`id-token: write`, minimal `permissions`), run the kit's scripts from `factory/` (`working-directory`), never use `pull_request_target`, and use the `gh-lab` environment for gated stages.
4. `platform-whatif.yml` is read-only: `Test-Preflight` and `-WhatIf` for ALZ-lite. `platform-foundation.yml` runs `Deploy-AlzLite.ps1` behind the reviewer gate.
5. `scripts/Test-PipelineSetup.ps1`: a doctor check of identity, credential, roles, environment, variables and OIDC login, with a fix printed per failure in the style of `Test-Preflight.ps1`. `Initialize-PlatformPipeline.ps1` runs it last.
6. `Import-Kit.ps1` installs the workflows and the guard into the repo root `.github/` (workflows run with `working-directory: factory`), adds them to the weekly sync `EXCLUDE_PATHS`, and keeps the lint ignores the first-commit flow needs. The kit repo's own copy runs in `factory/` too.
7. Tests: the guard refuses a wrong prefix and a wrong subscription; the foundation stage deploys under `mg-factory-ci` in the sandbox; the identity can't read or write the live lab; the private-repo fallback (no reviewer) is tested.
8. Workflows are clean under `actionlint`.

## Deliverables

- `.github/actions/guard/action.yml`, `.github/workflows/platform.yml`, `platform-whatif.yml`, `platform-foundation.yml`.
- `scripts/Test-PipelineSetup.ps1`; changes to `scripts/Import-Kit.ps1` and `scripts/Initialize-PlatformPipeline.ps1`.
- Tests under `test/` where the repo's test setup allows; evidence in the PR body.

## Verify

- `actionlint`, PSScriptAnalyzer and `npm run check` pass.
- A foundation run is green; the what-if run changes nothing.
- The negative tests fail as expected.

## Done when

- [ ] `platform.yml` runs what-if and foundation from Actions.
- [ ] The guard refuses a wrong subscription and prefix.
- [ ] Onboarding is one command plus a green doctor check.

## Commit message

```text
feat: add the platform entry workflow, guard and onboarding
```

## Stop and ask if

- A policy blocks the foundation deployment.
- A Tenant Root role would be needed.

## Notes and traps

- Environment secrets exist only inside a job, so the matrix can't read them.
- Pin actions the way the repo's other workflows do.
