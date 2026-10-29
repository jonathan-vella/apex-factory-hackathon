---
title: GitHub Copilot upgrade
description: Setting up and working on vm-dev01, and running the Upgrade agent in VS Code, following the golden path the kit validated.
sidebar:
  order: 5
---

This guide covers the mechanics of working on `vm-dev01` and running GitHub Copilot's Upgrade agent against Contoso University. It's the how. [Step 3: Datacenter and workstation](../../deploy/member-steps/#33-set-up-vm-dev01) sends you here to set up the VM once. [C3](../../challenges/c03-assess-the-source/) and [C6](../../challenges/c06-modernize-with-ghcp/) are the what and the acceptance bar.

## Switching to vm-dev01

You set up `vm-dev01` in [Step 3: Datacenter and workstation](../../deploy/member-steps/#33-set-up-vm-dev01) and reconnect to it whenever a restart ends your session. From C3 you leave the dev container for the app work, because the Upgrade agent's **Local** harness has to run next to the app and the datacenter's private network. (A harness is where the agent runs. **Local** runs it on this VM.) The steps below are the setup you do once, in Step 3, so that C3 opens on a ready VM. Never stop or deallocate `vm-dev01` during the event: it's your workstation for the rest of the event.

On `vm-dev01` you have two folders. Keep them apart:

| Folder | What it is | Branch | Use it for |
| --- | --- | --- | --- |
| `C:\src\factory` | A clone of the public kit (its `origin`), with your own repo added as a second remote named `member` | `vm-dev01-work` | Code: the app and the Upgrade agent's changes. You push to `member`. |
| `C:\src\<your-repo>` | A plain clone of your own repo (the one from [Set up your repo](../../deploy/set-up-your-repo/)) | `main` | Evidence: files in `factory\evidence\`. |

A remote is a saved name for a repository's URL. `<your-org>` and `<your-repo>` are the owner and name of your own repo: copy them from its page on GitHub. `<workload-subscription-id>` is your `$s.subscriptionId`; step 1 prints it.

Before you start:

- **Bastion** opens the VM's Windows desktop in a browser tab, through the Azure portal. The VMs have no public IP, so it's the only way in. Allow pop-ups for the portal, because the session opens in a new tab. When the browser asks to see the clipboard, choose **Allow**: that's how you paste commands into the VM. If you missed the prompt, use the lock icon in the address bar.
- **Use two browser windows:** one for the Bastion tab, one for the portal and this site. You can also read this site in the VM's own browser at `https://factory.apexops.pro/`. Enter the sign-in codes below on your own computer, where your passkeys and password manager work.
- **Use PowerShell 7 on the VM.** Open the Start menu, type `pwsh` and open **PowerShell 7**. Don't use **Windows PowerShell** (version 5.1): the commands below need 7. `$PSVersionTable.PSVersion` must show 7.x.

Step 1 runs in your dev container and step 2 in the Azure portal on your own computer. Steps 3 to 9 run on `vm-dev01`.

1. **Get the password and two values for later.** In your dev container, open a terminal, start `pwsh` and go to `factory/`:

   ```powershell
   cd factory
   $s = Get-Content .local/settings.json | ConvertFrom-Json
   (Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
   $s.subscriptionId
   git remote get-url origin
   ```

   The first line is the password; the user name is `labadmin`. The second is your workload subscription ID (`<workload-subscription-id>` in step 4) and the third is your repo URL (the one to use for `<your-org>` and `<your-repo>` in steps 6 and 7). Keep them next to you, because the VM has no `factory/.local` folder. The password file is in your repo folder (git-ignored), so it survives a dev container rebuild. The same password opens `vm-app01`. `Get-PipelineEvidence.ps1` creates the password file when you save your evidence in [Step 3: Datacenter and workstation](../../deploy/member-steps/#34-save-and-commit-your-readiness-evidence); if it's missing, finish that step first.
2. **Connect through Bastion.** In the Azure portal on your own computer, use the search box to find **Resource groups**, check the directory and subscription filter shows your workload subscription, then open `rg-datacenter` > `vm-dev01` > **Connect** > **Bastion**. Set **Authentication type** to **Password**, enter `labadmin` and the password, and choose **Connect**. After your first ever sign-in, wait up to five minutes before you open VS Code: the VM installs VS Code's extensions, including the Upgrade extension, for your user then. If you work from a Windows computer, `./scripts/Connect-DatacenterVm.ps1` is an optional shortcut that opens a Remote Desktop session through Bastion. It needs PowerShell 7, the Azure CLI with its `bastion` extension and a Windows-side copy of the `factory/` folder, so most people skip it.
3. **Sign in to GitHub and set your git identity.** In PowerShell 7 on the VM:

   ```powershell
   gh auth login --web
   gh auth setup-git
   $u = gh api user | ConvertFrom-Json
   git config --global user.name ($u.name ?? $u.login)
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   ```

   `gh auth login --web` asks a few questions: choose **GitHub.com**, **HTTPS**, and **Yes** to authenticate Git. It then prints a one-time code: open `https://github.com/login/device` on your own computer and enter it. `gh auth setup-git` lets `git push` use that sign-in, so you never type a password. The git identity is needed because the first commit fails without it.
4. **Sign in to Azure and use your own identity.** Still on the VM:

   ```powershell
   az login --use-device-code
   az account set --subscription '<workload-subscription-id>'
   az account show --query name -o tsv
   [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
   ```

   Enter the code at `https://microsoft.com/devicelogin` on your own computer. If your tenant blocks device code sign-in, run `az login` in the Bastion session instead. The last `az` command must print your workload subscription, the one with `rg-datacenter`. The environment variable makes the app's Azure calls use your own Azure CLI sign-in, because your own identity holds the data roles; without it the app gets 403 from Blob, Service Bus and Key Vault. Set it only on `vm-dev01`: on App Service the app uses its managed identity. It only reaches programs you start afterward, so don't open VS Code before this step.
5. **Refresh the kit clone, once.** The deployment already cloned the public kit to `C:\src\factory`. The kit sits at its root, not in a `factory/` folder. Refresh it now, before you create your work branch (step 6), and never again after that:

   ```powershell
   cd C:\src\factory
   git switch main
   git pull
   ```

   If `C:\src\factory` is missing, see the note after step 9.
6. **Connect the clone to your own repo and start your work branch, once.** The clone's `origin` is the public kit, and you can't push to it. Add your own repo as the `member` remote and put your work on its own branch:

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

7. **Clone your own repo for evidence, once.** This is a separate folder from the kit clone: never mix them.

   ```powershell
   git clone https://github.com/<your-org>/<your-repo>.git C:\src\<your-repo>
   ```

   Your repo's `main` already holds the kit import, because you merged the import in [Step 1: Repo and preflight](../../deploy/set-up-your-repo/#13-merge-your-import). The clone starts on `main`, and stays there.
8. **Open the kit clone in VS Code and sign in to Copilot.** Open its root, not the `app` folder, so the Upgrade agent finds `.github/skills/` and `.github/modernization/`:

   ```powershell
   code C:\src\factory
   ```

   Choose **Yes, I trust the authors** when VS Code asks. Then select the **Accounts** icon at the bottom left, choose **Sign in with GitHub to use GitHub Copilot**, and finish the sign-in in the browser.
9. **Set up the Upgrade agent.** In VS Code:
   - Check that **GitHub Copilot upgrade** is installed and enabled (**Extensions**). If **GitHub Copilot modernization** is installed, choose **Disable (Workspace)** for it.
   - In the Chat panel, set the harness (**Session Target**) to **Local**. Don't use the Copilot coding agent harness: it runs remotely and can't reach the VM's local SQL Server or the datacenter's private network.
   - Give the Upgrade server model access once: **MCP: List Servers** (in the Command Palette, `F1`) > **Upgrade** > **Configure Model Access**, and allow the models you'll use. Without it the agent can't call a model.
   - Open Copilot Chat and send "hello".

<details>
<summary>C:\src\factory is missing (step 5)</summary>

Before the event, ask your team lead; on event days, ask your coach. If your team lead asks you to clone it yourself, make the same sparse clone that the deployment makes, so the coach and facilitator folders stay out of it. (A sparse clone leaves some folders out of the working tree.) Run the commands exactly as written:

```powershell
git clone --no-checkout https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\factory
cd C:\src\factory
git sparse-checkout set --no-cone '/*' '!/coach/' '!/facilitator/' '!/docs/' '!/site/' '!/test/' '!/.vale/' '!/.vale.ini' '!/.markdownlint-cli2.mjs' '!/.prettierignore' '!/prettier.config.mjs' '!/lefthook.yml' '!/package.json' '!/package-lock.json' '!/.node-version' '!/.nvmrc'
git checkout
```

</details>

### Check your setup

Setting up `vm-dev01` is done when all of this is true. Run the commands in PowerShell 7 on the VM:

```powershell
gh auth status                                                   # signed in to github.com
git config --global user.name                                    # your name, not empty
az account show --query name -o tsv                              # your workload subscription
[Environment]::GetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'User')   # AzureCliCredential
git -C C:\src\factory remote -v                                  # origin (public kit) and member (your repo)
git -C C:\src\factory branch -vv                                 # * vm-dev01-work tracking member/vm-dev01-work
git -C C:\src\<your-repo> branch --show-current                  # main
git -C C:\src\factory status --short --ignored -- app .github    # prints nothing
```

Also check that VS Code is open on `C:\src\factory`, the agent picker lists **Upgrade** and Copilot Chat answers "hello".

If the last git command prints something, a clone left over from an earlier attempt would steer the agent. Remove the leftovers (it deletes files that git doesn't track, and ignored files, in those two folders):

```powershell
cd C:\src\factory
git clean -ndx -- app .github    # dry run: read the list
git clean -fdx -- app .github
```

### Coming back later

Each time you return to the VM, repeat steps 1 and 2 (password, Bastion), open PowerShell 7 and run `code C:\src\factory`. Nothing else needs doing. Read the challenge pages on the published site, `https://factory.apexops.pro/`, in the VM's browser or on your own computer. The modernization files are at `C:\src\factory\.github\modernization\` and the app is at `C:\src\factory\app\ContosoUniversity`. On newly deployed VMs the clone doesn't include the event's `coach/`, `facilitator/`, `docs/` and `site/` folders; the playbook, the skills and `app/` are all there.

If you restart the VM, do it only when no agent run is in progress: a restart ends your Bastion session and stops a run in the middle.

## Save your work and keep the branches straight

You have one repo of your own on GitHub. Your dev container holds a clone of it, and on `vm-dev01` it has a second, plain clone for evidence. The code you change on the VM lives in the kit clone, on its own branch. Keep this table in mind; most confusion comes from mixing them up.

| Where | Repo | Branch | What's there |
| --- | --- | --- | --- |
| Your dev container (readiness check, C1, C2, C4, C5, C10; C8 in part) | Your own repo | `main` | The accelerator, plus the kit in `factory/` |
| `vm-dev01`, `C:\src\factory` (C3, C6, C7, C9) | The public kit (`origin`), connected to your repo (`member`) | `vm-dev01-work` | The kit at the repo root: the app and your changes |
| `vm-dev01`, `C:\src\<your-repo>` (C3, C6, C7, C9; C8 in part) | Your own repo | `main` | Evidence only, in `factory\evidence\` |

After each task, commit and push to your branch. Because step 6 set the upstream, a plain `git push` goes to `member/vm-dev01-work`:

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
- **Don't run `git pull` in `C:\src\factory`** after step 5. Pulling the public kit's `main` into your work branch causes conflicts. If a coach tells you to, they'll give the exact command. (Evidence is different: you do pull in `C:\src\<your-repo>`, see below.)
- **Never push to `origin`.** It's the public kit and the push is refused. Push with a plain `git push`, or `git push member vm-dev01-work`.
- **Never merge `vm-dev01-work` into your repo's `main`, or open a pull request from it.** It would put the kit at the repo root next to the accelerator and break the dev container setup. GitHub shows a "Compare & pull request" banner for the branch: ignore it. Don't delete the branch either.
- **If `git push` says "no upstream branch"**, run `git push -u member vm-dev01-work`. **If it says permission denied** for the public kit repo, you pushed to `origin`: run `git branch -vv`, then `git push -u member vm-dev01-work`.
- **If a coach moves you to another branch**, keep working and pushing on that branch with the coach's commands. Your earlier `vm-dev01-work` branch stays as a backup. Don't switch back to it.

:::

### Copy your evidence to your repo

Your assessors read your evidence on `main` in your own repo, not your work branch. Each team member keeps evidence in their own repo; there's no shared team repo. One rule applies everywhere:

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
Copy-Item "$plan\assessment.md", "$plan\plan.md" $dest
git add $dest
git commit -m "docs: C3 assessment and plan"
git push
```

For C6, C7 and C9, put your screenshots, notes and fix scripts in the same kind of folder (`factory\evidence\c06`, `c07`, `c09`), then run the same `git add`, `git commit` and `git push`. Screenshots and exported reports go in the same folder.

Use a conventional commit message (`type: Subject`, for example `docs: C3 assessment`); the dev container's commit hook rejects anything else. Push to `main`; no pull request is needed. If the push is rejected because `main` moved, run `git pull --rebase` in `C:\src\<your-repo>` and push again. In your dev container, run `git pull` before you commit evidence there, or its next push is rejected. Don't commit tenant IDs, subscription IDs or secrets. Never merge `vm-dev01-work` into `main`.

## Assess and plan

Start a new chat, select the Upgrade agent, and send the exact text in `.github/modernization/plan-prompt.txt` (the playbook's Step 1 shows how to copy it with its characters intact). Review the assessment at the assessment gate. (A gate is a point where the agent stops so you can review before it continues.) Approve planning, then check the plan gate: the agent stops with `plan.md`, the seven-task plan. That's the end of [C3](../../challenges/c03-assess-the-source/): the plan is approved there, and commit `app: assess and plan` is your baseline. Task execution starts in C6.

## Run the tasks

One task per new chat. For each task: start it, let the agent make its changes, build the app, run it locally and check against the task's specific validation (see the playbook's task table in `.github/modernization/playbook.md`), then commit before starting the next task's chat. Don't batch multiple tasks into one chat: each task's check depends on the previous one already being committed.

## Model guidance

Use a balanced model for assessment, the most capable model for planning, and a balanced model for execution. See the playbook's [Models table](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models) for current picker guidance. These model classes were validated on 2026-10-02; names change, so follow the class guidance rather than a fixed model name.

## Local configuration after task 01

Task 01 (the .NET 10 / ASP.NET Core MVC conversion) resets the project's `UserSecretsId`. Run the `dotnet user-secrets set` block in the playbook's **Local configuration** section again after task 01 completes, or the app falls back to a default that won't match your environment.

## Where this hands off

If you prefer to paste ready-made prompts for each step, the [prompt library](../../prompts/) has them, for VS Code and (best effort) the GitHub Copilot app. The playbook stays the source for the checks.

The playbook's step 3 (closing gaps the tasks don't fully cover) uses three skills built for this app: `aspnet-startup-migration`, `notification-service-di` and `trace-to-opentelemetry`. If a task's own validation doesn't pass, check whether one of those skills' symptoms matches before escalating.

C6 continues past the seven tasks with the playbook's step 4 (package the app with .NET SDK container publishing and push it to your registry, skill `sdk-container-publish`) and step 5 (check the App Service configuration, skill `app-service-configuration`). Step 5 only checks in C6. Its commands that change Azure (the Key Vault secret, the web app's image) belong to C7, after the data is migrated.
