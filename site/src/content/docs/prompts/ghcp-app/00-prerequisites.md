---
title: "Copilot App: prerequisites"
description: Four checks before you select the Upgrade agent in the GitHub Copilot app.
sidebar:
  order: 1
---

The kit validated VS Code, not the Copilot app. If the Upgrade agent's tools don't attach after these four
checks, switch to the [VS Code track](../../vscode/00-prerequisites/) — don't keep retrying.

## 1. .NET 10 SDK installed

The Upgrade agent's MCP server runs through `dnx`, which needs the .NET 10 SDK. Without it, the agent's tools
never attach, with no error shown.

```powershell
dotnet --list-sdks
```

If nothing starts with `10.`, install it, then **fully quit and restart the Copilot app** — it doesn't pick up
a PATH change in an already-running app:

```powershell
winget install Microsoft.DotNet.SDK.10
```

## 2. The project folder is trusted

If the folder isn't trusted in the Copilot app when a session starts, selecting the Upgrade agent silently has
no effect: it shows as selected for a few seconds, then the session falls back to the default agent with none
of the Upgrade tools, and nothing tells you this happened.

**Action:** in the app, open the project's settings and trust the repository, *before* you select the Upgrade
agent and send your first message. If you already sent a message with the agent dropped, start a new session
after trusting the folder.

## 3. Sandboxing is off for this project

With sandboxing on, the Upgrade agent's read-only tools (`get_state`, `get_scenarios`, `get_instructions`) work
fine, but `initialize_scenario` — which writes `.github/upgrades/scenarios/dotnet-version-upgrade/` — fails
with an access-denied error, even though the sandbox panel shows the workspace as read/write.

**Action:** in the project's sandbox settings, turn off **Sandbox new sessions** before you start.

## 4. `AZURE_TOKEN_CREDENTIALS` set, so the app can reach Azure locally

Once a task has the app calling Blob, Service Bus or Key Vault, it needs your own Azure CLI sign-in — the
app's managed identity only applies once it's actually running on App Service. Without this, calls return 403.

```powershell
[Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
```

Set it only on `vm-dev01`, then restart the Copilot app so new sessions pick it up.

## Check all four before you continue

| Check | How |
| --- | --- |
| SDK installed | `dotnet --list-sdks` lists a `10.x` entry |
| App restarted after install | You quit and reopened the Copilot app since installing the SDK |
| Folder trusted | Project settings show the repository as trusted |
| Sandboxing off | Project settings show **Sandbox new sessions** off |
| `AZURE_TOKEN_CREDENTIALS` set | Set at the user level, and the app restarted since |

With all five true, continue to [Assess and plan](../01-assess-and-plan/).
