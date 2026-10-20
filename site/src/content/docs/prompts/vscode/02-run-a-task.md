---
title: "VS Code: run a task"
description: One task per new chat, build and run after every one.
sidebar:
  order: 3
---

## Before you send

A new chat, harness **Local**, agent **Upgrade**, the execution model (balanced at Medium reasoning, or an
efficient model at maximum reasoning).

## The prompt

Use **Start** on the task in the Upgrade dashboard's **Execution** tab, or send:

```text
Start task <task-id> with start_task. Scope: app/ContosoUniversity and .github/upgrades only; never edit files outside them.
```

Task IDs are in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md` (for example `01-aspnetcore-net10`).
Approve builds and file edits as they come up; if the agent stops halfway, reply `continue`.

## After the agent finishes

1. Build and `dotnet run` the app — the agent's own validation can pass without the app ever starting.
2. Run that task's check:

   | Task | Check |
   |---|---|
   | 01 .NET 10 / ASP.NET Core MVC | Build passes; the five pages load against `10.10.<n>.4`; `Global.asax`/`App_Start` gone; container properties in the project file (base image, repository `contoso-university`, port 8080); no `Dockerfile`; `/Notifications/GetNotifications` returns `success:true` |
   | 02 SQL Managed Instance | Development still reads/writes against the source; Production refuses a SQL login (`$env:ASPNETCORE_ENVIRONMENT='Production'; dotnet run --no-launch-profile`, then unset the variable) |
   | 03 Blob | Upload/replace/delete round-trips through Blob (`az storage blob list ...`); non-image and >5MB rejected; no `blob.core.windows.net` link on the page |
   | 04 Service Bus | A toast appears within 5 seconds of a student edit; `/Notifications/GetNotifications` returns `success:true` |
   | 05 Key Vault | A: Development without `KeyVault:VaultUri` runs. B: Production without it refuses to start. C: Production with it opens the vault, then stops for no `ConnectionStrings--DefaultConnection` yet (C7 writes it) |
   | 06 OpenTelemetry | With no connection string the app starts normally; with one, requests/SQL/traces show in Application Insights within 5 minutes; `git grep -n -E "Trace\.\|Debug\.Write" -- app/ContosoUniversity` prints nothing |
   | 07 CVE audit | `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` finds nothing, or a documented no-op |

   Full hot-spot table and the task 05/06 command blocks are in the
   [playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#task-checks).
3. Commit and push `app: task 0N <name>` before starting the next task's chat.

## Local configuration

Task 01 gives the project a new `UserSecretsId`. Re-set your user secrets afterward — the exact commands are in
the playbook's **Local configuration** section.

## Hot spots for every task

| Symptom | Fix |
|---|---|
| `start_task` fails with "internal LLM client unavailable" or "plan.md could not be parsed" | You're in the Copilot harness — switch to **Local** and start a new chat |
| The agent edits files outside `app/` and `.github/upgrades/` | Restore them with `git restore <path>` before you commit |
| The agent offers extra work (Aspire, ARM64, reports) | Decline — it's out of scope |
