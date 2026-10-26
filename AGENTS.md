# AGENTS.md

Rules for coding agents and people who change this repo, the Partner Modernization Factory kit. If your task is
modernizing Contoso University (`app/ContosoUniversity`, the Upgrade agent), follow
[.github/copilot-instructions.md](.github/copilot-instructions.md) instead. If you're executing a backlog item, also
follow [docs/backlog/AGENTS.md](docs/backlog/AGENTS.md). Pipeline workflows have their own rules in
[.github/workflows/AGENTS.md](.github/workflows/AGENTS.md).

## What this repo is

A public template repo for a two-day partner hackathon. Attendees create their own repo from `apex-accelerator`, import
this kit into `factory/` with `scripts/Import-Kit.ps1`, and run its scripts. Scope and decisions are in
[docs/prd.md](docs/prd.md), phases in [docs/roadmap.md](docs/roadmap.md), work items in [docs/backlog](docs/backlog/README.md).

## Read before you design or sequence anything

The order of events is fixed. Take it from [facilitator/guide.md](facilitator/guide.md) and
[facilitator/agenda.md](facilitator/agenda.md), never from memory or from the order the scripts happen to be listed in:

| When | Who | What | Notes |
|---|---|---|---|
| T-14 | Event owner, members | The event owner captures every subscription ID, index, object ID and email. Members run `Test-Preflight.ps1` | Access, quota, Copilot policy |
| T-7 | Platform lead (their repo, lead profile) | `Deploy-AlzLite.ps1` (the pipeline's `foundation` stage), once per team | Needs Owner at Tenant Root, or at the parent group. Creates `id-sqlmi-directory` |
| T-7, after ALZ-lite | A Privileged Role Administrator | `Grant-SqlMiDirectoryRead.ps1`, once per team | Manual, tenant-wide. Can't happen before ALZ-lite, and must happen before C7 |
| T-3 | **Each member**, in their own repo and their own workload subscription | `Deploy-Datacenter.ps1`, then `Test-Datacenter.ps1`, then `Connect-DatacenterArc.ps1` (C0), or the pipeline's `member` stage | The test goes **before** Arc: Arc turns off the run commands the test uses. Never redeploy the datacenter after Arc. Then the portal assessment and `vm-dev01` setup |
| T-1 | Platform lead | `Deploy-Vending.ps1` for every member, one after another, then VM restart, `New-DatacenterExemptions.ps1`, `Test-Connectivity.ps1` (the pipeline's `vending` stage) | Needs every member's datacenter **and** the foundation, and comes after the coach's C0 review and `vm-dev01` setup. A datacenter redeploy requires vending again |
| Day 1 | Everyone | Start at C1. C2 verifies and explains the foundation | C2 keeps its 35 team points |
| Day 1, C5 | Each member | The CoE archetype with `azd provision` | Out of scope for the platform pipeline |
| T+2 | Platform lead, members, an admin | The `teardown` stage (or `Remove-FactoryEnvironment.ps1`: every member scope first, then the team scope), then `Remove-PlatformPipeline.ps1` | |

So: **datacenter before vending, ALZ-lite before vending, vending before the archetype.** The only hard dependencies are
ALZ-lite and each datacenter before vending, `Test-Datacenter` before Arc, and the Graph grant after ALZ-lite and before C7.
Vending comes after `vm-dev01` setup. A team has **one shared services subscription and one workload subscription per
member**, and one Entra tenant. The pipeline is optional: the scripts stay the supported manual path. If a design or
workflow puts steps in another order, stop and check the guide.
Roles: the **event owner** plans and cleans up; **coaches** demo and sign off; the **platform lead** deploys ALZ-lite and
vends every member (and is also a member); **members** run their own C0 and everything after C2. There is no shared team repo:
each member keeps evidence in `factory/evidence/` of their own repo.

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
- Don't print IDs. Mask them in errors.
- Tests live in `test/`. `./test/Test-Preflight.Tests.ps1` and `./test/Assert-PipelineGuard.Tests.ps1` run without Azure. Keep them green.
- On Windows, `$h` is an alias of `Get-History`: don't name a helper `h`. Pass scripts to WSL with LF line endings.
- Don't rewrite files with PowerShell string replaces: use the edit tool, because CRLF in the working copy defeats a `` `n `` match silently.

## Checks to run

`npm run check` (content invariants, node tests, markdownlint, Prettier on the site), PSScriptAnalyzer on changed scripts, `actionlint` on changed workflows, `az bicep build` and `az bicep lint` on changed Bicep. Don't run `npx prettier --write` on `docs/`: the repo doesn't format Markdown with it, and it rewrites unrelated tables.

## Git and PRs

- Branch per item, conventional commits, short messages, with the Copilot trailers. The owner squash-merges. Open PRs as drafts, never merge or push to `main`, and mark an in-progress PR "do not merge".
- **Pipeline changes** (.github/workflows/platform.yml, the pipeline scripts) are tested in a lab you may delete, never against the owner's live subscriptions, and each live run needs the owner's approval. Never approve a gate for an action the owner hasn't authorized.
- Always name a PR or issue by its number when you ask the owner anything.
- Never commit to a branch another PR depends on without saying so. Stacked PRs target the previous branch.
