---
title: "Copilot App: assess and plan"
description: Run C3 in the Copilot app — the same plan-prompt.txt as VS Code.
sidebar:
  order: 2
---

Same prompt, same scenario, same gates as the [VS Code track](../../vscode/01-assess-and-plan/) — the
underlying Upgrade MCP workflow doesn't differ by host. Only the setup differs.

## Before you send

1. Finish [Prerequisites](../00-prerequisites/): SDK installed, app restarted since, folder trusted, sandboxing
   off.
2. Open the kit clone's root (`C:\src\factory`) as the project, on your `vm-dev01-work` branch.
3. Start a new chat and select the **Upgrade** agent from the agent picker.

## The prompt

Paste the whole of `.github/modernization/plan-prompt.txt` with its characters intact:

```powershell
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Get-Content -Raw -Encoding utf8 .github\modernization\plan-prompt.txt | Set-Clipboard
```

Then paste the clipboard into the chat and send it. Answer the pre-initialization confirmation as the prompt
says: target `net10.0`, **Guided**, stay on the current branch, commit strategy **Manual**, branch sync off.

## If the agent's tools never attach

If the very first turn doesn't call `get_state`/`get_scenarios`, or the agent reports the Upgrade workflow
tools aren't available: don't keep retrying in the same chat. Start one brand-new chat (not several at once —
each Upgrade MCP server instance is shared across sessions on the machine, and piling up chats makes
diagnosing harder). If it still fails, switch to [VS Code](../../vscode/01-assess-and-plan/): the playbook
already documents this as a known Copilot-app limitation.

## Check the assessment gate

- `.github/upgrades/scenarios/dotnet-version-upgrade/` has `assessment.md`, `assessment.json` and
  `dependencies-health.json`.
- The Upgrade dashboard canvas's **Assessment** tab shows data (open it from the agent picker or ask the agent
  to open it).

Approve planning, then check the plan gate:

- `plan.md`, `scenario-instructions.md` and `scenario.json` exist.
- Exactly seven tasks, in a strict chain: .NET 10, SQL Managed Instance, Blob, Service Bus, Key Vault,
  OpenTelemetry, CVE audit.
- No task mentions `#skill:migrating-webapi-odata`.
- `git status --short -- app` prints nothing.

Commit and push `app: assess and plan` — your baseline for C6.
