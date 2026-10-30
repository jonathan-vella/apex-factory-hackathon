---
title: GitHub Copilot upgrade
description: Setting up and working on vm-dev01, and running the Upgrade agent in VS Code, following the golden path the kit validated.
sidebar:
  order: 2
---

**For:** every member modernizing Contoso University on `vm-dev01`.

**Validated on:** 2026-10-30 (documentation review). Runtime baseline: GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, recorded in `versions.md`; no new runtime test is claimed. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`. The owner retests the current extension before the dry run.

**When:** [C3](../../challenges/c03-assess-the-source/), [C6](../../challenges/c06-modernize-with-ghcp/), [C7](../../challenges/c07-migrate-and-go-live/), [C8](../../challenges/c08-validate-the-pattern/) and [C9](../../challenges/c09-optimize-the-db-with-ghcp/).

**Before you start:** finish [Step 3.3: Set up vm-dev01](../../deploy/member-steps/#33-set-up-vm-dev01). This guide explains the agent workflow and branch rules; the challenges set the acceptance bar.

## Switching to vm-dev01

The setup now lives entirely in [Step 3.3: Set up vm-dev01](../../deploy/member-steps/#33-set-up-vm-dev01), including steps 1 to 9 for Bastion, sign-ins, the two clones and the Local harness. If you are reconnecting, use [Coming back later](../../deploy/member-steps/#coming-back-later); do not repeat clone or branch creation.

### Check your setup

Use [Check your setup in Step 3](../../deploy/member-steps/#check-your-setup) for the commands and clean-tree recovery.

### Coming back later

Use [Coming back later in Step 3](../../deploy/member-steps/#coming-back-later). Never stop `vm-dev01` during the event.

## Save your work and keep the branches straight

You have one repo of your own on GitHub. Your dev container holds a clone of it, and on `vm-dev01` it has a second, plain clone for evidence. The code you change on the VM lives in the kit clone, on its own branch. Keep this table in mind; most confusion comes from mixing them up.

| Where | Repo | Branch | What's there |
| --- | --- | --- | --- |
| Your dev container (readiness check, C1, C2, C4, C5, C10; C8 in part) | Your own repo | `main` | The accelerator, plus the kit in `factory/` |
| `vm-dev01`, `C:\src\factory` (C3, C6, C7, C9) | The public kit (`origin`), connected to your repo (`member`) | `vm-dev01-work` | The kit at the repo root: the app and your changes |
| `vm-dev01`, `C:\src\<your-repo>` (C3, C6, C7, C9; C8 in part) | Your own repo | `main` | Evidence only, in `factory\evidence\` |

After each task, commit and push to your branch. Because [Step 3.3, item 6](../../deploy/member-steps/#33-set-up-vm-dev01) set the upstream, a plain `git push` goes to `member/vm-dev01-work`:

```powershell
cd C:\src\factory
git add -A
git commit -m "app: task 0N <name>"
git push
```

`0N` is the task's number and `<name>` its short name, as in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md`. For example, task `01-aspnetcore-net10` is `app: task 01 aspnetcore-net10`.

Your own repo now has the `vm-dev01-work` branch next to `main`. The two branches have nothing in common (different folder layout), and that's expected.

:::caution[Don't mix up the branches]

- **Stay on `vm-dev01-work`** in `C:\src\factory`. Check with `git branch -vv` before you commit. Don't commit on `main` there.
- **Don't run `git pull` in `C:\src\factory`** after [Step 3.3, item 5](../../deploy/member-steps/#33-set-up-vm-dev01). Pulling the public kit's `main` into your work branch causes conflicts. If a coach tells you to, they'll give the exact command. (Evidence is different: you do pull in `C:\src\<your-repo>`, see below.)
- **Never push to `origin`.** It's the public kit and the push is refused. Push with a plain `git push`, or `git push member vm-dev01-work`.
- **Never merge `vm-dev01-work` into your repo's `main`, or open a pull request from it.** It would put the kit at the repo root next to the accelerator and break the dev container setup. GitHub shows a "Compare & pull request" banner for the branch: ignore it. Don't delete the branch either.
- **If `git push` says "no upstream branch"**, run `git push -u member vm-dev01-work`. **If it says permission denied** for the public kit repo, you pushed to `origin`: run `git branch -vv`, then `git push -u member vm-dev01-work`.
- **If a coach moves you to another branch**, keep working and pushing on that branch with the coach's commands. Your earlier `vm-dev01-work` branch stays as a backup. Don't switch back to it.

:::

### Copy your evidence to your repo

Your assessors read written evidence on `main` in your own repo; C6 also uses the app work branch for task commits. Each member keeps evidence in their own repo; there's no shared team repo. One rule applies everywhere:

- **Dev container:** evidence goes in `factory/evidence/` on `main`; run `git pull` first.
- **`vm-dev01`:** evidence goes in `C:\src\<your-repo>\factory\evidence\...` (the plain clone of your own repo) on `main`; run `git pull --rebase` first.

For a team document, one person types, then every teammate saves the final file under the same name in their own `factory/evidence/cNN/`.

After a challenge, on the VM, copy its files into the plain clone and push. This example is C3. For another challenge, replace `c03` and the files you copy:

```powershell
cd C:\src\<your-repo>
git pull --rebase
$dest = "factory\evidence\c03"
New-Item -ItemType Directory -Force $dest | Out-Null
$plan = "C:\src\factory\.github\upgrades\scenarios\dotnet-version-upgrade"
Copy-Item "$plan\assessment.md", "$plan\assessment.json", "$plan\plan.md" $dest
git add $dest
git commit -m "docs: C3 assessment and plan"
git push
```

For [C6](../../challenges/c06-modernize-with-ghcp/), [C7](../../challenges/c07-migrate-and-go-live/) and [C9](../../challenges/c09-optimize-the-db-with-ghcp/), put your screenshots, notes and fix scripts in the same kind of folder (`factory\evidence\c06`, `c07`, `c09`), then run the same `git add`, `git commit` and `git push`. Screenshots and exported reports go in the same folder.

Use a conventional commit message (`type: Subject`, for example `docs: C3 assessment`); the dev container's commit hook rejects anything else. Push to `main`; no pull request is needed. If the push is rejected because `main` moved, run `git pull --rebase` in `C:\src\<your-repo>` and push again. In your dev container, run `git pull` before you commit evidence there, or its next push is rejected. Don't commit tenant IDs, subscription IDs or secrets. Never merge `vm-dev01-work` into `main`.

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
