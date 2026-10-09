---
title: Prerequisites
description: Accounts, tools and the one repo you set up before T-14.
---

:::caution[Required before C0]
Every attendee, including the platform lead, must finish this whole page first: create your own repo from the `apex-accelerator` template, open it in the dev container, import the kit and write your settings. C0 and every later challenge run from that dev container, and nothing works without it.
:::

Complete this page by **T-14**, then continue with [C0: Ready to hack](../../challenges/c00-ready-to-hack/). If any blocker below applies to you, raise it with your coach now; don't leave it for event day.

## Blockers: you are not ready if any of these is true

- GitHub Copilot Chat or agent mode doesn't work in VS Code with your account.
- The models the APEX agents use are blocked by your account or organization policy.
- You have no Azure workload subscription, or you share one with another member.
- You can't register an MFA method for your Azure identity.
- The dev container doesn't open on your machine.

## How you work: one repo, one dev container

You work in **one repo of your own**: a private repo created from the [`apex-accelerator`](https://github.com/jonathan-vella/apex-accelerator) template. It brings the dev container (Azure CLI, PowerShell 7, Git, `azd`, Bicep) and the APEX agents. A single import command then copies the kit into a `factory/` folder at the root of that repo. From then on you run every kit script from `factory/` inside the dev container, and the archetype for C5 is already in place.

Your team also has **one shared team repo**, created from `templates/team/` (C1 onward). Your coach tells you who creates it.

## Accounts and access

| What | Requirement |
| --- | --- |
| GitHub | A personal account in the partner's GitHub org, with GitHub Copilot enabled (agent mode and the Upgrade agent allowed by policy). |
| Azure subscription | One workload subscription per member. Azure Pass is not supported; CSP, EA, pay-as-you-go and Visual Studio subscriptions are. |
| Azure role | Owner on your workload subscription. If your organization blocks Owner, ask your coach whether Contributor plus Resource Policy Contributor is accepted. |
| MFA | Registered for your Azure identity. |
| Region quota | Enough regional vCPU quota in `swedencentral` for a Standard_D8as_v6 VM (8 vCPUs, ×2: `vm-app01` and `vm-dev01`). |
| Platform lead only | A **second** subscription (shared services) plus Owner at Tenant Root. The platform lead is also a member: they still need their own workload subscription, and do C0 on it like everyone else. |

Check your subscription and quota from any terminal that has the Azure CLI:

```powershell
az login
az account show --output table
az vm list-usage --location swedencentral --output table
```

## Install on your machine

You only need the host tools to open the dev container; everything else is inside it.

| Tool | Why | Verify |
| --- | --- | --- |
| [VS Code](https://code.visualstudio.com/) 1.100 or newer | The editor and agent mode | `code --version` |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or another Docker-compatible runtime) | Runs the dev container | `docker version` |
| [Git](https://git-scm.com/downloads) | Clone your repo | `git --version` |
| VS Code extensions: Dev Containers (`ms-vscode-remote.remote-containers`), GitHub Copilot Chat (`github.copilot-chat`) | Open the container; Copilot sign-in | `code --list-extensions` |

```powershell
code --install-extension ms-vscode-remote.remote-containers
code --install-extension github.copilot-chat
```

### Windows 11 from scratch

1. Install [WSL](https://learn.microsoft.com/windows/wsl/install) with Ubuntu (`wsl --install`), then restart.
2. Install Docker Desktop and turn on **Use the WSL 2 based engine**.
3. Install VS Code and the **WSL** extension (`ms-vscode-remote.remote-wsl`) as well as the two above.
4. In Ubuntu, create a folder for your repos: `mkdir -p ~/repos`.
5. Clone your repo (below) into `~/repos`, not into a Windows folder: the dev container is much faster, and line endings stay correct.

### Network

Allow outbound HTTPS to `github.com`, `api.github.com`, `*.githubusercontent.com`, `api.githubcopilot.com`, `*.azure.com`, `*.microsoft.com`, `login.microsoftonline.com`, `learn.microsoft.com`, `docker.io` and `registry-1.docker.io`.

## Create your repo and import the kit

1. Open the [`apex-accelerator`](https://github.com/jonathan-vella/apex-accelerator) template, choose **Use this template** > **Create a new repository**, set the owner to your partner org, and make it **Private**.
2. Clone it (replace the placeholders) and open it in VS Code:

   ```bash
   cd ~/repos
   git clone https://github.com/<your-org>/<your-repo>.git
   code <your-repo>
   ```

3. When VS Code offers it, choose **Reopen in Container** (or press `F1` > `Dev Containers: Reopen in Container`). Wait for the build to finish.
4. In the dev container terminal, at the repo root, import the kit. Paste these three lines as they are:

   ```bash
   curl -fsSLO https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/scripts/Import-Kit.ps1
   pwsh ./Import-Kit.ps1
   rm Import-Kit.ps1
   ```

   This creates `factory/` (scripts, infra, app, db, templates, archetype) and imports the CoE archetype's APEX project into the repo root. It refuses to overwrite an existing `factory/` unless you add `-Force`.
5. Commit the result:

   ```bash
   git add -A && git commit -m "Import kit" && git push
   ```

The archetype was built against APEX commit `c209d8b` (recorded in `archetype/README.md`). If the APEX agents in your repo behave differently from the C5 instructions, tell your coach.

## Sign in and create your settings file

In the dev container terminal:

```powershell
az login --use-device-code
gh auth login
cd factory
./scripts/Initialize-Settings.ps1
```

The script asks for your tenant ID and workload subscription ID (it offers the ones from your `az login`), your member index and your location (press Enter for `swedencentral`). It checks each value and writes `factory/.local/settings.json`.

**Member index:** your coach assigns you a number from 1 to 20 from the event roster. Ask your coach if you don't have one; don't pick your own.

**Shared services subscription:** press Enter to skip it for now. The platform lead shares its ID in the team channel at the start of C2, and you add it then by re-running `./scripts/Initialize-Settings.ps1 -SharedSubscriptionId <id>`. Re-running never changes your other values.

`factory/.local/` is git-ignored: your IDs never go to GitHub. Run every script from the `factory/` folder.

## Manual checks

`Test-Preflight.ps1` (C0, task 1) can't verify these; confirm them yourself before T-14:

| # | Check | How to verify |
| --- | --- | --- |
| 1 | Copilot Chat responds in VS Code | Open Copilot Chat, send "hello". |
| 2 | The APEX custom agents appear | In Copilot Chat's agent picker, `01-Orchestrator` and `08-As-Built` are listed. |
| 3 | The agents' models are permitted | The picker lets you select and run them (no policy block message). |
| 4 | The MCP servers in `.vscode/mcp.json` load | VS Code shows them started and authenticated. |
| 5 | Dev container opens | You can run `az version` and `pwsh --version` in its terminal. |
| 6 | One subscription per member | Confirm with your coach. |
| 7 | Your roles match your kit role | Platform lead: Tenant Root Owner and a separate shared services subscription. Members: Owner on your own workload subscription. |

See the [ALZ-lite guide](../../guides/alz-lite/) for why the model needs two kinds of subscription. When all of this is green, go to [C0: Ready to hack](../../challenges/c00-ready-to-hack/).
