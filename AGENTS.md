# AGENTS.md

Rules for coding agents and people who change this repo, the Partner Modernization Factory kit. If your task is
modernizing Contoso University (`app/ContosoUniversity`, the Upgrade agent), follow
[.github/copilot-instructions.md](.github/copilot-instructions.md) instead. If you're executing a backlog item, also
follow [docs/archive/backlog/AGENTS.md](docs/archive/backlog/AGENTS.md). Pipeline workflows have their own rules in
[.github/workflows/AGENTS.md](.github/workflows/AGENTS.md).

## What this repo is

A public template repo for a two-day partner hackathon. Attendees create their own repo from `apex-accelerator`, import
this kit into `factory/` with `scripts/Import-Kit.ps1`, and deploy and tear down the platform from GitHub Actions. Scope and decisions are in
[docs/archive/prd.md](docs/archive/prd.md), phases in [docs/archive/roadmap.md](docs/archive/roadmap.md), work items in [docs/archive/backlog](docs/archive/backlog/README.md).

## Read before you design or sequence anything

The order of events is fixed. Take it from [facilitator/guide.md](facilitator/guide.md) and
[facilitator/agenda.md](facilitator/agenda.md), never from memory or from the order the scripts happen to be listed in:

| When | Who | What | Notes |
|---|---|---|---|
| Step 1 (T-14) | Team lead, members | Everyone sets up their repo, pipeline and settings, runs `Test-Preflight.ps1` (`whatif` stage), and shares their subscription ID, index, object ID and email privately with the team lead, who keeps `roster.json`. The event owner confirms the rosters | Access, quota, Copilot policy. No coach on duty before day one; team lead is first point of contact |
| Step 2 (T-7) | Team lead (their repo, lead profile) | The `foundation` stage (runs `Deploy-AlzLite.ps1`), once per team | Needs Owner at Tenant Root, or at the parent group. Creates `id-sqlmi-directory` |
| Step 2 (T-7, after ALZ-lite) | A Privileged Role Administrator | `Grant-SqlMiDirectoryRead.ps1`, once per team | Manual, tenant-wide. Can't happen before ALZ-lite, and must happen before C7 |
| Step 3 (T-3) | **Each member**, in their own repo and their own workload subscription | The `member` stage (`Deploy-Datacenter.ps1`, then `Test-Datacenter.ps1`, then `Connect-DatacenterArc.ps1`; input `no-hybrid-benefit`): the readiness setup | The test goes **before** Arc: Arc turns off the run commands the test uses. Never redeploy the datacenter after Arc. Then the portal assessment, `vm-dev01` setup, and committing `factory/evidence/readiness/` |
| Step 4 (T-1) | Team lead (after everyone starts their VMs) | The `vending` stage (`Invoke-PipelineVending.ps1`: checks `vnet-datacenter` and `vm-app01` Arc `Connected` status, runs `Deploy-Vending.ps1` for every member one after another, then VM restart, `New-DatacenterExemptions.ps1`, `Test-Connectivity.ps1`) | Needs every member's Arc-connected datacenter **and** the foundation, and comes after `vm-dev01` setup. A datacenter redeploy requires vending again |
| Day 1 | Everyone | 08:30 tech lead 30-min PPT intro, then C1 at 09:00 (CAF Strategy) and C2 at 09:45 (15 member pts, 45 min: test AI coding agent against repo + ALZ guardrails) | Base score is 170 points (45 team + 125 member), plus up to 30 bonus = 200 max |
| Day 1, C5 | Each member | The CoE archetype with `azd provision` | Out of scope for the platform pipeline |
| T+2 | Team lead, members, an admin | The `teardown` stage (`Remove-FactoryEnvironment.ps1`: every member scope first, then the team scope), then `Remove-PlatformPipeline.ps1` | |

So: **datacenter before vending, ALZ-lite before vending, vending before the archetype.** The only hard dependencies are
ALZ-lite and each datacenter before vending, `Test-Datacenter` before Arc, and the Graph grant after ALZ-lite and before C7.
Vending comes after `vm-dev01` setup. A team has **one shared services subscription and one workload subscription per
member**, and one Entra tenant. GitHub Actions is the only way students deploy the datacenter, the foundation and vending, and
tear them down. The scripts are the engine the stages run, they stay in use for challenge tasks, and a coach runs one by hand only
as a repair when an Actions run can't be repaired in time. If a design or
workflow puts steps in another order, stop and check the guide.
Roles: the **event owner** plans and cleans up; **coaches** demo and sign off on event days (not during pre-hackathon setup, where support is best-effort); the **team lead** (a colleague the team nominates, called the platform lead in the workflow and scripts) is the first point of contact for teammates, deploys ALZ-lite and
vends every member (and is also a member); **members** run their own readiness setup and member challenges. A team is three to five people, the team lead included. There is no shared team repo:
each member keeps evidence in `factory/evidence/` of their own repo. The readiness setup has no points and isn't a challenge: `Invoke-PipelineVending.ps1` automatically checks that each member's `vnet-datacenter` exists and `vm-app01` is `Connected` in Azure Arc before vending. Student pages never offer running the deploy scripts by hand; the manual path is the coach-only page `coach/deploy-with-scripts.md`.

## Rules that apply everywhere

- **No identifiers in the public repo, its logs or PR bodies.** Tenant, subscription, object, client and resource IDs,
  budget addresses and real public IPs stay in gitignored `.local/` files and GitHub environment **secrets**. Use
  placeholders such as `<subscription-id>`. A public repo's Actions logs are public, and they print variables: never put an
  identifier in a variable, never `echo` one. Scan every diff for GUIDs before you commit.
- **Lab provisioning is IaC and scripts, never agents** (datacenter, ALZ-lite, vending, policy, teardown). Agents are only for the CoE work, app modernization and DB modernization. Never run APEX agents unattended against live Azure.
- **The kit never changes Contoso University's code.** Students modernize it with Copilot. Lifelines are for coaches.
- **Never waive or work around a tenant policy**, and never make a public endpoint that isn't a documented exception.
- **Never touch the owner's live lab** (the subscriptions in `.local/settings.json`) while testing. Test in the lab named in `.local/ci-lab.json`.
- **Ask before you deploy or delete** anything in Azure, unless the owner's prompt pre-authorizes it by name. In autopilot, `ask_user` gets an automatic reply that is never approval: stop and report instead.
- Datacenter VM disks are Premium. Bastion is Standard only. No availability zones are pinned or enabled. SQL MI is paid General Purpose, never the free offer.

## Scripts (`scripts/`, imported into attendees' `factory/`)

- PowerShell 7.4 with `#Requires -Version 7.4`, `[CmdletBinding()]`, typed parameters, `$ErrorActionPreference = 'Stop'`, comment-based help with an example. Must work in Azure Cloud Shell (Linux): use `Join-Path`.
- Clean under PSScriptAnalyzer. Run it on every script you touch.
- A script must work for a user **and** for the pipeline's managed identity. Treat a login as the pipeline only when `az account show` reports `user.type` of `servicePrincipal`; take its object ID from the ARM token's `oid` claim, never from `az ad signed-in-user show` (Graph). List role assignments by scope and filter on `principalId`, not with `--assignee`.
- Don't print IDs. Mask them in errors. Pipeline steps pipe their output through `scripts/Write-RedactedOutput.ps1`, which turns every GUID into `<id:abcd>`, as a second line of defence.
- Tests live in `test/`. Every PowerShell test there runs without Azure (each uses stubs or fixtures, and its header says so): `Assert-PipelineGuard`, `Invoke-PipelineVending`, `Test-Acceptance`, `Test-DatacenterRetry`, `Test-DevSparse`, `Test-Helpers`, `Test-MiLinkSource`, `Test-Preflight` and `Write-RedactedOutput`, each as `./test/<name>.Tests.ps1`. The `.mjs` tests belong to `npm run check`. Keep them all green.
- On Windows, `$h` is an alias of `Get-History`: don't name a helper `h`. Pass scripts to WSL with LF line endings.
- Don't rewrite files with PowerShell string replaces: use the edit tool, because CRLF in the working copy defeats a `` `n `` match silently.

## Checks to run

`npm run check` (content invariants, node tests, markdownlint, Prettier on the site), PSScriptAnalyzer on changed scripts (settings in `PSScriptAnalyzerSettings.psd1`), `actionlint` on changed workflows, `az bicep build` and `az bicep lint` on changed Bicep. CI enforces them: `validate-docs.yml` runs the docs checks and Vale, and `validate-scripts.yml` runs PSScriptAnalyzer, every `test/*.Tests.ps1`, `actionlint` and Bicep lint when scripts, tests, infra or workflows change. Don't run `npx prettier --write` on `docs/`: the repo doesn't format Markdown with it, and it rewrites unrelated tables.

## Git and PRs

- Branch per item, conventional commits, short messages, with the Copilot trailers. The owner squash-merges. Open PRs as drafts, never merge or push to `main`, and mark an in-progress PR "do not merge".
- **Pipeline changes** (.github/workflows/platform.yml, the pipeline scripts) are tested in a lab you may delete, never against the owner's live subscriptions, and each live run needs the owner's approval. Never approve a gate for an action the owner hasn't authorized.
- Always name a PR or issue by its number when you ask the owner anything.
- Never commit to a branch another PR depends on without saying so. Stacked PRs target the previous branch.
