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
2. `platform.yml` (`workflow_dispatch`) has a `stage` input: `whatif`, `foundation`, `all`, plus a `member-index` input (default `1`). B18 and B19 add `member`, `vending` and `teardown`. Every job sits in this one file, because a reusable workflow can't read the environment's secrets (tested: they arrive empty). Member details come from the `ROSTER_JSON` secret inside the gated job, because `secrets` can't be used in `strategy`. The composite action `.github/actions/platform-session` reads the roster, runs the guard and logs in.
3. Jobs use `azure/login` with OIDC (`id-token: write`, minimal `permissions`), run the kit's scripts from `factory/` (`working-directory`), never use `pull_request_target`, and use the `gh-lab` environment for gated stages.
4. The `whatif` stage is read-only: `Test-Preflight` and an ALZ-lite `-WhatIf` (skipped with a notice when the kit's groups don't exist yet under a non-root parent). The `foundation` stage runs `Deploy-AlzLite.ps1` behind the reviewer gate.
5. `scripts/Test-PipelineSetup.ps1`: a doctor check of identity, credential, roles, workflows, environment, variables and secrets, with a fix printed per failure in the style of `Test-Preflight.ps1`. `Initialize-PlatformPipeline.ps1` runs it last. It can't prove the OIDC login itself: the first workflow run does.
6. Identifiers (tenant, client, subscriptions, roster) are environment **secrets**, not variables: a public repo's logs print variables. The session action masks every ID. Only `LOCATION`, `MG_PREFIX`, `PARENT_MG` and `DENIED_MG_PREFIXES` are variables.
7. `Import-Kit.ps1` installs the workflows and both actions into the repo root `.github/` (`KIT_DIR` becomes `factory`), adds them to the weekly sync `EXCLUDE_PATHS` and to `.prettierignore`. The kit repo's own copy runs in `.`.
8. Tests: the guard refuses a wrong prefix and a wrong subscription (`test/Assert-PipelineGuard.Tests.ps1`); the foundation stage deploys under `mg-factory-ci` in the sandbox; the identity can't read or write the live lab; the private-repo fallback (no reviewer) is tested in B20's fresh-repo run.
9. Workflows are clean under `actionlint`.

## Deliverables

- `.github/actions/guard/action.yml`, `.github/actions/platform-session/action.yml`, `.github/workflows/platform.yml`.
- `scripts/Assert-PipelineGuard.ps1`, `scripts/Test-PipelineSetup.ps1`; changes to `scripts/Import-Kit.ps1` and `scripts/Initialize-PlatformPipeline.ps1`.
- `test/Assert-PipelineGuard.Tests.ps1`; evidence in the PR body.

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

- Environment secrets exist only inside a job, so the matrix can't read them, and a reusable workflow can't read them at all.
- Never put identifiers in variables or `echo` them: a public repo's logs are public.
- Pin actions the way the repo's other workflows do.
