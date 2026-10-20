---
title: "Copilot App: run a task"
description: One task per new chat, the same check table as the playbook.
sidebar:
  order: 3
---

One task per new chat, same as VS Code. The Upgrade dashboard canvas opens automatically if the agent's
plugin registered it; otherwise ask the agent to open it.

## Before you send

Harness has no meaning in the Copilot app (there's no Local/Copilot split), but the equivalent still applies:
run this on `vm-dev01`, against the on-premises database, not against a remote sandbox.

## The prompt

```text
Start task <task-id> with start_task. Scope: app/ContosoUniversity and .github/upgrades only; never edit files outside them.
```

Task IDs are in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md` (for example `01-aspnetcore-net10`).

## After the agent finishes

1. Build and `dotnet run` the app yourself — the agent's own validation can pass without the app ever
   starting.
2. Run that task's check from the playbook's task table (same table for both tracks):

   | Task | Check |
   |---|---|
   | 01 .NET 10 / ASP.NET Core MVC | Build passes; the five pages load against the on-premises database; `Global.asax`/`App_Start` gone; container properties in the project file; no `Dockerfile` |
   | 02 SQL Managed Instance | Development still reads/writes against the source; Production refuses a SQL login |
   | 03 Blob | Upload/replace/delete round-trips through Blob; non-image and >5MB rejected; no `blob.core.windows.net` link on the page |
   | 04 Service Bus | A toast appears within 5 seconds of a student edit; `/Notifications/GetNotifications` returns `success: true` |
   | 05 Key Vault | Development without `KeyVault:VaultUri` runs; Production without it refuses to start; Production with it reaches the vault |
   | 06 OpenTelemetry | With no connection string the app starts normally; with one, requests/SQL/traces show in Application Insights; no leftover `Trace`/`Debug` calls |
   | 07 CVE audit | `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` finds nothing, or a documented no-op |

   Full hot-spot details are in the [playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#task-checks).
3. Commit and push `app: task 0N <name>` before starting the next task's chat.

Re-set your user secrets after task 01 (it gives the project a new `UserSecretsId`) — see the playbook's
**Local configuration** section.
