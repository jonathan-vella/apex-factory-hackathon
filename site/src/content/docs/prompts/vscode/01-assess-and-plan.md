---
title: "VS Code: assess and plan"
description: Run C3 — the kit's validated path.
sidebar:
  order: 2
---

## Before you send

1. Finish [Prerequisites](../00-prerequisites/).
2. A new chat, harness **Local**, agent **Upgrade**, a balanced model (Sonnet- or Terra-class) for the
   assessment — see the playbook's [Models](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models)
   table.

## The prompt

Paste the whole of `.github/modernization/plan-prompt.txt` with its characters intact:

```powershell
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Get-Content -Raw -Encoding utf8 .github\modernization\plan-prompt.txt | Set-Clipboard
```

Then paste the clipboard into the chat and send it. Answer the pre-initialization confirmation as the prompt
says: target `net10.0`, **Guided**, stay on the current branch, commit strategy **Manual**, branch sync off.

## Check the assessment gate

- `.github/upgrades/scenarios/dotnet-version-upgrade/` has `assessment.md`, `assessment.json` and
  `dependencies-health.json`.
- The Upgrade dashboard's **Assessment** tab shows data.

Switch to the most capable model (Opus- or Sol-class, Medium reasoning), then approve planning. Check the plan
gate:

- `plan.md`, `scenario-instructions.md` and `scenario.json` exist.
- Exactly seven tasks, in a strict chain: .NET 10, SQL Managed Instance, Blob, Service Bus, Key Vault,
  OpenTelemetry, CVE audit.
- All 9 rows of the rules table are met.
- No task mentions `#skill:migrating-webapi-odata`.
- `git status --short -- app` prints nothing.

If a check fails, tell the agent which one, in the same chat — it can revise its own plan. Commit and push
`app: assess and plan` — your baseline for C6. If you ever have to restart the seven tasks,
`git reset --hard` to this commit.

## Hot spots

| Symptom | Fix |
|---|---|
| The agent picks the `azure-migrate` scenario, or asks for GitHub Copilot modernization | The prompt wasn't sent whole — start a new chat and paste it again |
| The prompt arrives garbled | Copy it with the UTF-8 block above |
| "The Upgrade workflow tools aren't available", or no `assessment.json` | Reload the window (**Developer: Reload Window**) and start a new chat. Don't accept a hand-written assessment |
| The plan includes Entra ID user sign-in, Azure SQL Database or Azure Files | Point the agent at the rules table and ask it to revise the plan |
