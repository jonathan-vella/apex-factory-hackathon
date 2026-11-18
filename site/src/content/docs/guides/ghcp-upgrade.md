---
title: GitHub Copilot upgrade
description: Setting up and working on vm-dev01, and running the Upgrade agent in VS Code, following the golden path the kit validated.
sidebar:
  order: 2
---

**For:** every member modernizing Contoso University on `vm-dev01`.

**Validated on:** 2026-10-30 (documentation review). Runtime baseline: GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, recorded in `versions.md`; no new runtime test is claimed. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`. The owner retests the current extension before the dry run.

**When:** [C3](../../challenges/c03-assess-the-source/), [C6](../../challenges/c06-modernize-with-ghcp/), [C7](../../challenges/c07-migrate-and-go-live/), [C8](../../challenges/c08-validate-the-pattern/) and [C9](../../challenges/c09-optimize-the-db-with-ghcp/).

**Before you start:** finish setting up `vm-dev01` in [Step 3.3: Set up vm-dev01](../../deploy/member-steps/#33-set-up-vm-dev01) (Path A) or [Student onboarding §2](../../deploy/lead-setup/student-onboarding/#2-connect-to-vm-dev01-through-bastion-and-set-up-your-workspace) (Path B). This guide explains the agent workflow and single-clone layout; the challenges set the acceptance bar.

## Switching to vm-dev01

The setup lives in [Step 3.3: Set up vm-dev01](../../deploy/member-steps/#33-set-up-vm-dev01) for Path A and [Student onboarding §2](../../deploy/lead-setup/student-onboarding/#2-connect-to-vm-dev01-through-bastion-and-set-up-your-workspace) for Path B, covering Bastion, sign-ins, your single clone (`C:\src\<your-repo>` on `main`) and the Local harness. If you are reconnecting, use [Coming back later](../../deploy/member-steps/#coming-back-later); do not repeat the clone.

### Check your setup

Use [Check your setup in Step 3](../../deploy/member-steps/#check-your-setup) for the commands and clean-tree recovery.

### Coming back later

Use [Coming back later in Step 3](../../deploy/member-steps/#coming-back-later). Never stop `vm-dev01` during the event.

## Save your work in your single clone on `main`

You have **one private repo of your own on GitHub** (created in Step 1 in Path A, or assigned on your Handoff Card in Path B—never create a second GitHub repo), cloned once on `vm-dev01` at `C:\src\<your-repo>` on `main`. `Import-Kit.ps1` placed `app/ContosoUniversity`, `.github/modernization/`, `.github/skills/`, `infra/bicep/university/`, and `factory/` side by side in that single repository.

| Path inside `C:\src\<your-repo>` on `main` | What lives there |
| --- | --- |
| `app/ContosoUniversity/` and `.github/upgrades/` | Contoso University source code and Upgrade agent assessment/plan/task artifacts (C3, C6) |
| `agent-output/university/` and `infra/bicep/university/` | CoE archetype Bicep and `07-*.md` As-Built documentation (C5) |
| `factory/evidence/` | Working challenge deliverables (`c01` through `c10`, pre-populated by `Import-Kit.ps1`) |

After each Upgrade agent task in C6, commit and push on `main` from `C:\src\<your-repo>`:

```powershell
cd C:\src\<your-repo>
git add app/ContosoUniversity .github/upgrades
git commit -m "feat(app): task 0N <name>"
git push
```

`0N` is the task's number and `<name>` its short name, as in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md`. For example, task `01-aspnetcore-net10` is `feat(app): task 01 aspnetcore-net10`.

:::note[Reverting only `app` and `.github/upgrades` if you need to restart C6]

Because C1–C5 commits live on the same `main` branch in `C:\src\<your-repo>`, **never run `git reset --hard` or `git push --force`** if you want to restart the seven C6 tasks from your C3 baseline commit (`<c3-commit-sha>`). Instead, restore only `app` and `.github/upgrades`:

```powershell
cd C:\src\<your-repo>
git restore --source=<c3-commit-sha> --worktree --staged -- app .github/upgrades
git clean -fdx -- app .github/upgrades
```

:::

### Working artifacts in `factory/evidence/`

`Import-Kit.ps1` pre-populates `factory/evidence/` with the working templates (`c01/opportunity-canvas.md`, `c03/triage.md`, `c04/decisions-and-register.md`, `c07/cutover-rollback-runbook.md`, `c10/handover-and-ai-review.md`). Because `.github/upgrades/scenarios/dotnet-version-upgrade/` already sits at the root of `C:\src\<your-repo>` on `main`, you do not need to copy `assessment.md` or `plan.md` into `factory/evidence/c03/`—commit them in place alongside `factory/evidence/c03/triage.md`:

```powershell
cd C:\src\<your-repo>
git pull --rebase
git add .github/upgrades factory/evidence/c03/triage.md
git commit -m "docs: C3 assessment, plan and triage"
git push
```

Team deliverables (`C1`, `C4`, `C10`) are committed once in the team/pod lead's repository (`C:\src\<your-repo>` on `main`) and shared in the team channel for reference. Don't commit tenant IDs, subscription IDs or secrets.

## Assess and plan

Start a new chat, select the Upgrade agent, and send the exact text in `.github/modernization/plan-prompt.txt` (the playbook's Step 1 shows how to copy it with its characters intact). Review the assessment at the assessment gate. (A gate is a point where the agent stops so you can review before it continues.) Approve planning, then check the plan gate: the agent stops with `plan.md`, the seven-task plan. That's the end of [C3](../../challenges/c03-assess-the-source/): the plan is approved there, and commit `app: assess and plan` is your baseline. Task execution starts in C6.

## Run the tasks

One task per new chat. For each task: start it, let the agent make its changes, build the app, run it locally and check against the task's specific validation (see the playbook's task table in `.github/modernization/playbook.md`), then commit before starting the next task's chat. Don't batch multiple tasks into one chat: each task's check depends on the previous one already being committed.

## Model guidance

Use a balanced model for assessment, the most capable model for planning, and a balanced model for execution. See the playbook's [Models table](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models) for current picker guidance. These model classes were validated on 2026-10-02; names change, so follow the class guidance rather than a fixed model name.

## Local configuration after task 01

Task 01 (the .NET 10 / ASP.NET Core MVC conversion) resets the project's `UserSecretsId`. Run the playbook's **Local configuration** `dotnet user-secrets set` block after task 01 completes, and again whenever `UserSecretsId` changes, or the app falls back to a default that won't match your environment.

## Where this hands off

If you prefer to paste ready-made prompts for each step, the [prompt library](../../prompts/) has them, for VS Code and (best effort) the GitHub Copilot app. The playbook stays the source for the checks.

The playbook's step 3 (closing gaps the tasks don't fully cover) uses three skills built for this app: `aspnet-startup-migration`, `notification-service-di` and `trace-to-opentelemetry`. If a task's own validation doesn't pass, check whether one of those skills' symptoms matches before escalating.

C6 continues past the seven tasks with the playbook's step 4 (package the app with .NET SDK container publishing and push it to your registry, skill `sdk-container-publish`) and step 5 (check the App Service configuration, skill `app-service-configuration`). Step 5 only checks in C6. Its commands that change Azure (the Key Vault secret, the web app's image) belong to C7, after the data is migrated.
