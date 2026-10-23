# B21: Build the member profile: a pipeline in each member's own repo for C0

| Field | Value |
|---|---|
| Issue | #134 |
| Milestone | P6 Platform automation |
| Type | Both |
| Depends on | B18 |
| Unblocks | B22 |
| Effort | 3–5 days elapsed, including the owner's fresh-repo test |
| Cost | About $1.55/hour for the test datacenter while it exists |
| Teardown | Remove the test datacenter and the member's identity with B19's scripts |
| PRD | §2 Platform pipeline; §5 C0; §6 Platform pipeline |

## Outcome

- A member deploys their own datacenter from their own private repo with GitHub Actions instead of from a terminal: `Test-Preflight`, `Deploy-Datacenter`, `Test-Datacenter` (before Arc) and `Connect-DatacenterArc`. Nothing about C0 changes except where the commands run: the member still owns the deployment, in their own subscription, with their own approval.
- The 60-minute deploy no longer needs an open terminal and an awake computer.

## Why

C0 is member-owned pre-work, run from the member's own repo and dev container with their own sign-in (see `challenges/c00-ready-to-hack.md`). A pipeline in the platform lead's repo that deploys every datacenter doesn't match that. The member profile keeps the ownership and removes the fragile part.

## Requirements

1. `Initialize-PlatformPipeline.ps1 -Profile Member` creates the identity `id-factory-pipeline` and `rg-cicd` in the member's **own workload subscription**, with one federated credential for their repo's `gh-lab` environment. The identity is Owner on that subscription only: no shared services subscription, no management group, no Tenant Root role. The roster holds one member.
2. The workflow and actions work without a shared services subscription: `platform-session`, the guard and `Test-Preflight` treat it as optional. A member repo's `platform.yml` offers only the stages that fit: `whatif` (preflight) and `member`.
3. The settings file is the member's `factory/.local/settings.json`. Setup reads the subscription, index and region from it and asks for nothing else. `Test-PipelineSetup.ps1` knows the profile.
4. Setup copes with a **private repo**: if the plan has no required reviewers it says so and uses write access as the gate (the member is the only writer). It also reads the repo's OIDC subject claim.
5. The `member` stage keeps the C0 rules: the Arc refusal check, the test before Arc, fresh logins, and the VMs' scripts downloaded from the public kit (`KIT_REPOSITORY` and `KIT_REF` set by `Import-Kit.ps1`, never the member's private repo).
6. The run summary holds the `Test-Datacenter` output, which is the member's C0 evidence. A script or step saves it to `factory/evidence/c00/` (a pull request, an artifact or a download: pick the simplest that works and say why).
7. 🧑 HUMAN: the owner creates a throwaway private repo from `apex-accelerator`, imports the kit, and runs setup and the `member` stage as a student would, using only the docs from B20. Record every stumble.
8. `Import-Kit.ps1` installs the same workflow files for both profiles. The profile is decided by setup, not by the files.

## Deliverables

- `scripts/Initialize-PlatformPipeline.ps1` (profile), `scripts/Test-PipelineSetup.ps1`, `scripts/Remove-PlatformPipeline.ps1` (profile), changes to the session action, `platform.yml` and `Test-Preflight.ps1`.
- A C0 "run it from Actions" section (drafted here, finished in B22).
- Evidence in the PR body: the fresh-repo run, times, Actions minutes used, what was awkward.

## Verify

- PSScriptAnalyzer, actionlint, `npm run check` and the existing tests pass.
- The member stage is green from a private repo with no shared subscription, and the identity can't read any other subscription.

## Done when

- [ ] A member deploys, tests and Arc-onboards their datacenter from their own repo.
- [ ] The guard and the identity are limited to that one subscription.
- [ ] The fresh private repo test passed using only the docs.

## Commit message

```text
feat: add the member profile for the platform pipeline
```

## Stop and ask if

- The Actions minutes of a private repo on a free plan don't cover a deploy (about 100 minutes a run).
- The evidence can't be saved without the member doing manual work.

## Notes and traps

- **Fresh-repo test, 2026-10-22 (owner approved; PR #138 with #139):** a throwaway private repo from `apex-accelerator` (free plan, no reviewers), the kit imported at the PR branch, settings for a never-used subscription, `Initialize-PlatformPipeline.ps1 -Profile Member` with no extra parameters. Setup passed (reviewer gate WARN, write access as the gate). The `member` stage ran preflight with `-Fix` (about 2 minutes: registered the providers and the public IP feature), then deployed, tested (46 of 46) and Arc-onboarded in 35 minutes in total. `Get-PipelineEvidence.ps1` fetched the output. The identity is Owner on that one subscription only. Stumbles: the next-step text said to approve in the Actions tab though there was no gate (fixed); `Initialize-Settings.ps1` needs an Enter for the optional shared subscription prompt when scripted; a new subscription needs providers and the feature registered, so the member stage now always runs preflight first (B23).
- Evidence (requirement 6): the `member` stage uploads `Test-Datacenter` output as the artifact `c00-test-datacenter-member-<n>` (90 days), and `Get-PipelineEvidence.ps1` downloads it. An artifact needs no write access to the repo's branches and no pull request.
- The profile is the repository variable `PIPELINE_PROFILE` (the plan job has no environment, so it can't read an environment variable). With `member`, the plan job rejects the `foundation`, `vending` and `all` stages and the ALZ-lite what-if is skipped.
- The identity's object ID comes from the ARM token `oid`, not Graph, which can hit a CAE challenge.
- A private repo on a free plan has no required reviewers and limited Actions minutes.
- Arc can't be undone: the stage must refuse to redeploy over it.
