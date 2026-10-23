---
title: Platform pipeline
description: Optional GitHub Actions that deploy your datacenter (members) and the team's foundation (platform lead), with copy-paste setup, what it grants and the manual fallback.
sidebar:
  order: 3
---

This guide is optional. Everything it does, you can also do by running the kit's scripts yourself, as [C0](../../challenges/c00-ready-to-hack/) and [C2](../../challenges/c02-secure-ai-ready-foundation/) describe. The pipeline runs the same scripts from GitHub Actions, unattended, so you don't wait at a terminal for 30 minutes.

## Who runs what, and when

| When | Who | Profile | What runs |
|---|---|---|---|
| T-14 | Event owner | none | Captures the roster: every member's subscription ID, index, object ID and email. |
| T-7 | Platform lead | Lead | ALZ-lite (the `foundation` stage). A Privileged Role Administrator then runs the Graph grant, which no pipeline does. |
| T-3 | Each member | Member | Preflight, then datacenter, `Test-Datacenter`, and Arc onboarding (the `member` stage), in the member's own repo. |
| T-1 | Platform lead | Lead | Vending for every member, in order (the `vending` stage). |
| After the event | Platform lead, members, an admin | both | The `teardown` stage, then the cleanup script for the identity. |

A **member** pipeline lives in your own repo and can touch only your own workload subscription. A **lead** pipeline lives in the platform lead's repo and touches the team's shared services subscription and every member's workload subscription. They are two separate setups. Nobody needs the other's access.

The platform lead is also a member, but a repo can have only one profile. In the lead's repo, set up the lead profile and don't run `-Profile Member`. Do the lead's own C0 with the scripts in the dev container as [C0](../../challenges/c00-ready-to-hack/) describes, or run the lead pipeline's `member` stage for your own index (`gh workflow run platform.yml -f stage=member -f members=1`). Every other member uses the member profile in their own repo.

## What it grants, and why

Setup creates a managed identity called `id-factory-pipeline` in a resource group called `rg-cicd`. GitHub proves who it is with a short-lived OIDC token, so there is no password or secret to leak. The identity is trusted only for one GitHub environment, `gh-lab`, in one repo.

- **Member profile:** Owner on your own workload subscription. Nothing else.
- **Lead profile:** Owner at Tenant Root, so it can create the kit's management groups and move subscriptions (in a test lab, at a sandbox management group instead).

Why Owner: the kit assigns roles and policies, which Contributor can't do. The risk is real, so know it: anyone who can run a workflow in the environment can use that identity. Three guards limit it. The environment accepts only the branches you list. A required reviewer approves each run where your GitHub plan offers it (on a private repo without that feature, write access to the repo is the gate, so keep the repo private and the writers few). And a guard step refuses any subscription that isn't on its approved list. Use only a non-production tenant. The [coach page](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/facilitator/platform-pipeline.md) records the accepted risk.

Subscription IDs and your roster are stored as environment secrets, never in the repo or its logs.

## Member: Set up and run C0

Prerequisites are done and `factory/.local/settings.json` exists. From `factory/` in your own repo, signed in with `az login` and `gh auth login`:

```powershell
./scripts/Initialize-PlatformPipeline.ps1 -Profile Member
```

It asks for nothing. It prints a plan, creates the identity and the `gh-lab` environment, sets the secrets and checks the result. On a private repo with no reviewer option it warns that write access is the gate. That is expected.

Run the preflight, then the datacenter:

```bash
gh workflow run platform.yml -f stage=whatif
gh workflow run platform.yml -f stage=member
```

Approve the run in the **Actions** tab if GitHub asks. The `member` stage runs the preflight first (on a new subscription it registers the Azure providers and the public IP feature, which takes a few minutes), then deploys the datacenter, runs `Test-Datacenter` and, only if that passes, onboards `vm-app01` to Azure Arc. Plan on about 35 to 45 minutes. When it ends, download your C0 evidence:

```powershell
./scripts/Get-PipelineEvidence.ps1
```

That saves `evidence/c00/test-datacenter.txt` next to the scripts. Commit it as C0 describes. The pipeline never redeploys a datacenter that is already Arc-enabled, because Arc can't be undone.

Check the setup any time:

```powershell
./scripts/Test-PipelineSetup.ps1 -PipelineProfile Member
```

## Platform lead: Set up and run the foundation

You need your repo with the kit imported, `factory/.local/settings.json` including your shared services subscription, and the roster file from the event owner. From `factory/`:

```powershell
./scripts/Initialize-PlatformPipeline.ps1 -RosterPath <roster file>
```

The roster holds one row per member (`index`, `subscriptionId`, `memberPrincipalId`, `budgetEmail`). It goes into a secret. Then:

```bash
gh workflow run platform.yml -f stage=whatif
gh workflow run platform.yml -f stage=foundation
```

`foundation` deploys ALZ-lite in about 10 minutes. After it, a Privileged Role Administrator runs `scripts/Grant-SqlMiDirectoryRead.ps1` once for the team (see [ALZ-lite](../alz-lite/)). At T-1, once every member's datacenter exists:

```bash
gh workflow run platform.yml -f stage=vending
```

Vending runs members strictly one after another, because each run updates the shared firewall policy. One approval covers the stage.

## If you prefer the scripts, or something breaks

Every stage is a kit script you can run yourself: `Deploy-Datacenter.ps1`, `Deploy-AlzLite.ps1`, `Deploy-Vending.ps1`. The pipeline adds nothing the scripts don't do, and the scripts stay the supported path. If an Actions run fails, read its log, fix the cause and re-run the stage: the scripts are idempotent. After two attempts, ask your coach. See [Troubleshooting](../../reference/troubleshooting/) for specific errors.

## Taking it down

Both profiles have a `teardown` stage and a cleanup script for the identity, so nothing billable or privileged is left behind.

```bash
gh workflow run platform.yml -f stage=teardown
```

A member's run removes that member's datacenter, spoke and archetype. A lead's run removes every member first, then the team's foundation and management groups, and returns the subscriptions to the parent group. Tick `include-management` only for a lab you are retiring completely: it also deletes `rg-management` and `id-sqlmi-directory`, so a later event needs the Graph grant again.

The workflow can't remove its own identity. When it ends, run the identity cleanup script yourself as an admin:

```powershell
./scripts/Remove-PlatformPipeline.ps1            # lead
./scripts/Remove-PlatformPipeline.ps1 -Profile Member   # member
```

It removes the identity's roles, the identity, `rg-cicd`, the GitHub environment and the pipeline's repository variables, then checks that each is gone.
