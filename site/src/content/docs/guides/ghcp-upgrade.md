---
title: GitHub Copilot upgrade
description: Running the Upgrade agent in VS Code, following the B06 golden path.
---

This guide covers the mechanics of running GitHub Copilot's Upgrade agent against Contoso University. It's the how; [C6](../../challenges/c06-modernize-with-ghcp/) is the what and the acceptance bar.

## Switching to vm-dev01

From C6 you leave the dev container and work on `vm-dev01`, because the Upgrade agent's Local harness has to run next to the app and the datacenter's private network. The VM has Git, `gh`, VS Code and the Upgrade extension preinstalled.

1. **Get the password.** In your dev container, from `factory/`:

   ```powershell
   $s = Get-Content .local/settings.json | ConvertFrom-Json
   (Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
   ```

   The user name is `labadmin`. The file is in your repo folder (git-ignored), so it survives a dev container rebuild.
2. **Connect through Bastion.** In the Azure portal open `rg-datacenter` > `vm-dev01` > **Connect** > **Bastion**, enter `labadmin` and the password, and open the session. There's no public IP and no other way in.
3. **Sign in to GitHub.** In PowerShell on the VM:

   ```powershell
   gh auth login --web
   $u = gh api user | ConvertFrom-Json
   git config --global user.name $u.login
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   ```

   Follow the device-code prompt in the VM's browser.
4. **Open the kit.** The deployment already cloned the kit repo to `C:\src\factory`; you don't need your accelerator repo on the VM. Refresh it and open the app:

   ```powershell
   git -C C:\src\factory pull
   code C:\src\factory\app\ContosoUniversity
   ```

   If `C:\src\factory` is missing, clone it: `git clone https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\factory`.

The modernization files are at `C:\src\factory\.github\modernization\`. Your work stays in this local clone: commit after each task, but there is nothing to push.

## Setup

On your dev VM, after the steps above: sign in to Azure with device-code flow (`az login --use-device-code`), set the user-level environment variable `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` (the VM's own managed identity has no data-plane roles — every Azure SDK call in the app needs your own identity instead), and work from your clone's `app/ContosoUniversity`.

Open the repo in VS Code with the GitHub Copilot Upgrade extension installed. Use the **Local** harness and the **Upgrade** agent — not the Copilot coding agent harness, which runs remotely and can't reach the dev VM's local SQL Server or the datacenter's private network.

## Assess and plan

Start a new chat, select the Upgrade agent, and send the exact text in `.github/modernization/plan-prompt.txt`. Review the assessment and the proposed seven-task plan before approving it — this is the gate [C3](../../challenges/c03-assess-the-source/) is about.

## Run the tasks

One task per new chat. For each task: start it, let the agent make its changes, build the app, run it locally and check against the task's specific validation (see the playbook's task table in `.github/modernization/playbook.md`), then commit before starting the next task's chat. Don't batch multiple tasks into one chat — each task's check depends on the previous one already being committed.

## Model guidance

The golden path used Claude Opus 5.5 at Medium effort for assess and plan, and Claude Sonnet 5.5 at Medium effort for execution. Faster or cheaper models can work, but haven't been validated against this app's specific traps (see the playbook's hot-spot notes per task).

## Local configuration after task 01

Task 01 (the .NET 10 / ASP.NET Core MVC conversion) resets the project's `UserSecretsId`. Re-enter your local connection string and any other local secrets with `dotnet user-secrets set` after task 01 completes, or the app falls back to a default that won't match your environment.

## Where this hands off

The playbook's step 3 (closing gaps the tasks don't fully cover) uses three skills built for this app: `aspnet-startup-migration`, `notification-service-di` and `trace-to-opentelemetry`. If a task's own validation doesn't pass, check whether one of those skills' symptoms matches before escalating.
