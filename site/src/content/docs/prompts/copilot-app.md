---
title: Copilot app (best effort)
description: What to check before using the Upgrade agent in the GitHub Copilot app instead of VS Code.
sidebar:
  order: 9
---

The kit validated VS Code, not the Copilot app, and `vm-dev01` doesn't have the app. Use VS Code unless
you specifically want to try the app: to try it, install it on `vm-dev01` yourself first, because the work runs
there and the app has to run where your Azure sign-in and the source database are. If the Upgrade agent's tools don't attach after the checks below, switch
to the [VS Code prompts](../vscode/00-prerequisites/) and keep going. That's the documented fallback, not a sign
you did something wrong.

Everything else is the same: [the assess and plan steps](../vscode/01-assess-and-plan/), the same task prompts
and checks, the same branch rules. Use the VS Code pages for the prompts and checks, and run them in the app.

## Check these before you select the Upgrade agent

| Check | Why | How |
| --- | --- | --- |
| The app and Upgrade plugin are installed | The app doesn't include the Upgrade agent automatically. | Follow [Install GitHub Copilot upgrade](https://learn.microsoft.com/dotnet/core/porting/github-copilot-upgrade/install): install the app, add the `microsoft/upgrade-agent-plugins` marketplace in **Settings > Plugins**, then install **upgrade-agent**. Confirm **Upgrade** in the picker or `upgrade-agent:upgrade` in `/agent`. |
| The .NET 10 SDK is installed, and you restarted the app since | The Upgrade agent's tool server starts through `dnx`, which needs the .NET 10 SDK. Without it the tools never attach, and no error shows. The app doesn't pick up a PATH change while it's running. | `dotnet --list-sdks` lists a `10.x` entry. `vm-dev01` has it already. If you install it, fully quit and reopen the app. |
| The project folder is trusted | In a folder you haven't trusted, selecting the Upgrade agent shows as selected for a few seconds, then the session falls back to the default agent with none of the Upgrade tools, and nothing tells you. | In the project's settings, trust the repository before you select the agent. If the agent already dropped, trust the folder and start a new session. |
| The sandbox is off for the project | With the sandbox on, the read-only tools (`get_state`, `get_scenarios`) work, but `initialize_scenario` can't write `.github/upgrades/scenarios/dotnet-version-upgrade/` and fails with access denied, even though the sandbox panel shows the workspace as read/write. | In the project's sandbox settings, turn off **Sandbox new sessions**. |
| `AZURE_TOKEN_CREDENTIALS` is set, and the app restarted since | Once a task calls Blob, Service Bus or Key Vault, the app needs your own Azure CLI sign-in. Without it, calls return 403. | The user-level variable from step 4 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01). |

Open the kit clone's root (`C:\src\factory`) as the project, on your `vm-dev01-work` branch, then start a new chat
and pick **Upgrade** in the agent picker.

## If the agent's tools never attach

If the first turn doesn't call `get_state` or `get_scenarios`, or the agent says the Upgrade workflow tools aren't
available, don't keep retrying in the same chat:

1. Start one new chat. Don't open several, because the tool server is shared across sessions on the machine and
   piling up chats makes the problem harder to see.
2. If that fails too, fully quit and reopen the app, then try once in a single new chat.
3. Still failing: switch to VS Code and continue there. The playbook's
   [Copilot CLI section](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#with-copilot-cli-instead-of-vs-code)
   records the same limitation.

## Differences from VS Code

- There's no harness to choose and no Local or Copilot split. Run it on `vm-dev01` (install the app there first, as
  above), against the source database.
- The Upgrade dashboard opens in a side panel if the agent's plugin registered it. Otherwise ask the agent to open it,
  or read `plan.md` and `tasks.md` in `.github/upgrades/scenarios/dotnet-version-upgrade/`.

**Validated on:** 2026-10-30 (installation documentation checked against Learn; the app remains best effort, not the kit's runtime baseline).
