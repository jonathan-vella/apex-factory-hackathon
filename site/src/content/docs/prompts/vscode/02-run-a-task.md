---
title: "VS Code: run a task"
description: One task per new chat, build and run after every one.
sidebar:
  label: Run a task (C6)
  order: 4
---

Used in [C6, requirement 2](../../../challenges/c06-modernize-with-ghcp/#requirements).

**Validated on:** 2026-10-31 (documentation). Runtime baseline: GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, recorded in `versions.md`. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`, then use the `start_task` prompt below. Current-version runtime retesting remains the owner's pre-dry-run task.

## Before you send

A new chat on `vm-dev01`, VS Code opened on `C:\src\factory`, for **C6 requirement 2**; harness **Local**, agent **Upgrade**, and a balanced model for execution. Use the playbook's
[Models](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#models)
table as the single source for the picker names. You're on `vm-dev01-work` with a clean tree (see
[prerequisites](../00-prerequisites/)).

## The prompt

Start the task by sending:

```text
Start task <task-id> with start_task. Scope: app/ContosoUniversity and .github/upgrades only; never edit files outside them.
```

Task IDs are in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md` (for example `01-aspnetcore-net10`).
Approve builds and file edits as they come up; if the agent stops halfway, reply `continue`.

## After the agent finishes

1. Build and `dotnet run` the app. The agent's own validation can pass without the app ever starting.
2. Run that task's check from the playbook's
   [Task checks](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#task-checks)
   table. It is the single source for the seven checks and their hot spots.
3. Check you stayed in scope: `git status --short -- . ':!app' ':!.github/upgrades'` must print nothing.
4. Commit and push `app: task 0N <name>` to your work branch before you start the next task's chat. Check
   `git branch -vv` first, and keep the branches straight as in
   [Save your work and keep the branches straight](../../../guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight).

## Local configuration

Task 01 gives the project a new `UserSecretsId`. Set your user secrets again afterward. The exact commands are in
the playbook's [Local configuration](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#local-configuration)
section.

For task-specific checks and hot spots, follow [Step 2 of the playbook](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#step-2-run-the-tasks).

More help: [Troubleshoot](../04-troubleshoot/).
