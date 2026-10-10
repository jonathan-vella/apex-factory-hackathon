---
title: GitHub Copilot upgrade
description: Working on vm-dev01 and running the Upgrade agent in VS Code, following the golden path the kit validated.
sidebar:
  order: 3
---

This guide covers the mechanics of working on `vm-dev01` and running GitHub Copilot's Upgrade agent against Contoso University. It's the how; [C3](../../challenges/c03-assess-the-source/) and [C6](../../challenges/c06-modernize-with-ghcp/) are the what and the acceptance bar.

## Switching to vm-dev01

From C3 you leave the dev container and work on `vm-dev01`, because the Upgrade agent's Local harness has to run next to the app and the datacenter's private network. The VM has Git, `gh` and VS Code preinstalled. VS Code's extensions, including the Upgrade extension, install per user at your first sign-in, so that first sign-in takes a minute or two longer: wait for it to finish before you open VS Code. Never stop or deallocate `vm-dev01` during the event: it's your workstation for the rest of the event.

Step 1 runs in your dev container. Everything after it runs on `vm-dev01`.

1. **Get the password.** In your dev container, open a terminal, start `pwsh` and go to `factory/`:

   ```powershell
   cd factory
   $s = Get-Content .local/settings.json | ConvertFrom-Json
   (Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
   ```

   The user name is `labadmin`. The file is in your repo folder (git-ignored), so it survives a dev container rebuild. The same password opens `vm-app01`.
2. **Connect through Bastion.** In the Azure portal open `rg-datacenter` > `vm-dev01` > **Connect** > **Bastion**, enter `labadmin` and the password, and open the session. There's no public IP and no other way in. If you work from a Windows computer with the Azure CLI and its `bastion` extension, `./scripts/Connect-DatacenterVm.ps1 -SubscriptionId '<workload-subscription-id>'` (PowerShell 7, from the `factory/` folder of your repo on that computer, not in the dev container) opens a Remote Desktop session through Bastion instead. That's optional; the portal path needs nothing extra.
3. **Sign in to GitHub.** In PowerShell on the VM:

   ```powershell
   gh auth login --web
   gh auth setup-git
   $u = gh api user | ConvertFrom-Json
   git config --global user.name $u.login
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   ```

   Follow the device-code prompt in the VM's browser. `gh auth setup-git` lets `git push` use that sign-in, so you don't type a password.
4. **Refresh the kit clone, once.** The deployment already cloned the public kit repo to `C:\src\factory`. It's a separate copy from your own repo: the kit sits at its root, not in a `factory/` folder, and you don't need your accelerator repo on the VM. Refresh it now, before you create your work branch (step 5), and never again after that:

   ```powershell
   cd C:\src\factory
   git switch main
   git pull
   ```

   If `C:\src\factory` is missing, clone it: `git clone https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\factory`.
5. **Connect the clone to your own repo and start your work branch, once.** The clone's `origin` is the public kit repo, and you can't push to it. Add your own repo as a second remote, named `member`, and put your work on its own branch. Replace the placeholders with your GitHub organization and the repo you created in Prerequisites:

   ```powershell
   cd C:\src\factory
   git remote add member https://github.com/<your-org>/<your-repo>.git
   git switch -c vm-dev01-work
   git push -u member vm-dev01-work
   ```

   Check it. `git remote -v` must list `origin` (the public kit) and `member` (your repo). `git branch -vv` must show `* vm-dev01-work` tracking `member/vm-dev01-work`:

   ```powershell
   git remote -v
   git branch -vv
   ```

6. **Open the kit clone's root in VS Code**, not the `app` folder, so the Upgrade agent finds `.github/skills/` and `.github/modernization/`:

   ```powershell
   code C:\src\factory
   ```

The modernization files are at `C:\src\factory\.github\modernization\`. The app is at `C:\src\factory\app\ContosoUniversity`. On newly deployed VMs the clone doesn't include the event's `coach/`, `facilitator/`, `docs/` and `site/` folders; the playbook, the skills and `app/` are all there. Read the challenge pages on the published site, in the VM's browser.

## Save your work and keep the branches straight

You work in **two repos**, and each has its own branch. Keep this table in mind; most confusion comes from mixing them up.

| Where | Repo | Branch | What's there |
| --- | --- | --- | --- |
| Your dev container (C0 to C2, C5) | Your own repo | `main` | The accelerator, plus the kit in `factory/` |
| `vm-dev01`, `C:\src\factory` (C3, C6, C7, C9) | The public kit (`origin`), connected to your repo (`member`) | `vm-dev01-work` | The kit at the repo root: the app and your changes |
| The team repo (C1 onward) | Your team's evidence repo | `main` | Evidence only |

After each task, commit and push to your branch. Because step 5 set the upstream, a plain `git push` goes to `member/vm-dev01-work`:

```powershell
cd C:\src\factory
git add -A
git commit -m "app: task 0N <name>"
git push
```

Your own repo now has the `vm-dev01-work` branch next to `main`. The two branches have nothing in common (different folder layout), and that's expected.

:::caution[Don't mix up the branches]

- **Stay on `vm-dev01-work`** in `C:\src\factory`. Check with `git branch -vv` before you commit. Don't commit on `main` there.
- **Don't run `git pull`** after step 4. Pulling the public kit's `main` into your work branch causes conflicts. If a coach tells you to, they'll give the exact command.
- **Never push to `origin`.** It's the public kit and the push is refused. Push with a plain `git push`, or `git push member vm-dev01-work`.
- **Never merge `vm-dev01-work` into your repo's `main`, or open a pull request from it.** It would put the kit at the repo root next to the accelerator and break the dev container setup. GitHub shows a "Compare & pull request" banner for the branch: ignore it. Don't delete the branch either.
- **If `git push` says "no upstream branch"**, run `git push -u member vm-dev01-work`. **If it says permission denied** for the public kit repo, you pushed to `origin`: run `git branch -vv`, then `git push -u member vm-dev01-work`.
- **If a coach moves you to another branch**, keep working and pushing on that branch with the coach's commands. Your earlier `vm-dev01-work` branch stays as a backup. Don't switch back to it.

:::

### Copy your evidence to the team repo

Your assessors read the team repo, not your work branch. After a challenge, copy its evidence there (clone the team repo once, then repeat the rest). You need write access to it, from C1. Replace `<n>` with your member index and `c03` with the challenge:

```powershell
git clone https://github.com/<your-org>/<team-repo>.git C:\src\team-repo
cd C:\src\team-repo
git pull
$dest = "evidence\c03\member-<n>"
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item C:\src\factory\.github\upgrades\scenarios\dotnet-version-upgrade\assessment.md $dest
git add $dest
git commit -m "C3: member <n> assessment"
git pull --rebase
git push
```

The team repo is a different repo with its own `main`: this is the only place where you `git pull`. Don't commit tenant IDs, subscription IDs or secrets. Screenshots and exported reports go in the same folder.

## Where to run

After the password lookup in step 1, every command on this page runs on `vm-dev01`: the deployment cloned the kit to `C:\src\factory`, and the Upgrade agent works in that clone, on your `vm-dev01-work` branch. Connect through Bastion first: see [Switching to vm-dev01](#switching-to-vm-dev01). Don't run these in the dev container.

## Setup

The playbook's **Step 0: Set up** (`.github/modernization/playbook.md`) is the single source for the VM setup, so follow it rather than this page: the Azure CLI sign-in, `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` (your own identity holds the data-plane roles, so every Azure SDK call in the app has to use your Azure CLI sign-in), a clean legacy tree, and the Upgrade extension in the **Local** harness. Don't use the Copilot coding agent harness: it runs remotely and can't reach the dev VM's local SQL Server or the datacenter's private network. Two setup items trip people up, and Step 0 covers both: if **GitHub Copilot modernization** is installed, disable it for the workspace, and give the Upgrade server model access once (**MCP: List Servers** > **Upgrade** > **Configure Model Access**), or the agent can't call a model.

## Assess and plan

Start a new chat, select the Upgrade agent, and send the exact text in `.github/modernization/plan-prompt.txt` (the playbook's Step 1 shows how to copy it with its characters intact). Review the assessment at the assessment gate, approve planning, then check the plan gate: the agent stops with `plan.md`, the seven-task plan. That's the end of [C3](../../challenges/c03-assess-the-source/): the plan is approved there, and commit `app: assess and plan` is your baseline. Task execution starts in C6.

## Run the tasks

One task per new chat. For each task: start it, let the agent make its changes, build the app, run it locally and check against the task's specific validation (see the playbook's task table in `.github/modernization/playbook.md`), then commit before starting the next task's chat. Don't batch multiple tasks into one chat — each task's check depends on the previous one already being committed.

## Model guidance

The golden path used Claude Opus 5.5 at Medium effort for assess and plan, and Claude Sonnet 5.5 at Medium effort for execution. Faster or cheaper models can work, but haven't been validated against this app's specific traps (see the playbook's hot-spot notes per task).

## Local configuration after task 01

Task 01 (the .NET 10 / ASP.NET Core MVC conversion) resets the project's `UserSecretsId`. Re-enter your local connection string and any other local secrets with `dotnet user-secrets set` after task 01 completes, or the app falls back to a default that won't match your environment.

## Where this hands off

The playbook's step 3 (closing gaps the tasks don't fully cover) uses three skills built for this app: `aspnet-startup-migration`, `notification-service-di` and `trace-to-opentelemetry`. If a task's own validation doesn't pass, check whether one of those skills' symptoms matches before escalating.

C6 continues past the seven tasks with the playbook's step 4 (package the app with .NET SDK container publishing and push it to your registry, skill `sdk-container-publish`) and step 5 (check the App Service configuration, skill `app-service-configuration`). Step 5 only checks in C6. Its commands that change Azure (the Key Vault secret, the web app's image) belong to C7, after the data is migrated.
