---
title: "VS Code: run a task"
description: One task per new chat, build and run after every one.
sidebar:
  order: 3
---

## Before you send

A new chat, harness **Local**, agent **Upgrade**, the execution model (balanced at Medium reasoning, or an
efficient model at maximum reasoning). You're on `vm-dev01-work` with a clean tree (see
[prerequisites](../00-prerequisites/)).

## The prompt

Use **Start** on the task in the Upgrade dashboard's **Execution** tab, or send:

```text
Start task <task-id> with start_task. Scope: app/ContosoUniversity and .github/upgrades only; never edit files outside them.
```

Task IDs are in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md` (for example `01-aspnetcore-net10`).
Approve builds and file edits as they come up; if the agent stops halfway, reply `continue`.

## After the agent finishes

1. Build and `dotnet run` the app. The agent's own validation can pass without the app ever starting.
2. Run that task's check from the playbook's
   [Task checks](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#task-checks)
   table. It's the single source for the seven checks and their hot spots, so it isn't copied here. Two things it
   says that people miss:
   - Task 05 runs the app three ways (Development, Production without a vault, Production with one). The
     playbook has the command block.
   - Task 06 needs **Monitoring Metrics Publisher** on Application Insights for your own sign-in. The archetype
     grants it when you deploy it. Only for a deployment from before 2026-10-20 do you run the grant yourself; the
     command is in the same playbook section.
3. Check you stayed in scope: `git status --short -- . ':!app' ':!.github/upgrades'` must print nothing.
4. Commit and push `app: task 0N <name>` to your work branch before you start the next task's chat. Check
   `git branch -vv` first, and keep the branches straight as in
   [Save your work and keep the branches straight](../../../guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight).

## Local configuration

Task 01 gives the project a new `UserSecretsId`. Set your user secrets again afterward. The exact commands are in
the playbook's [Local configuration](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/.github/modernization/playbook.md#local-configuration)
section.

## Hot spots for every task

| Symptom | Fix |
|---|---|
| `start_task` fails with "internal LLM client unavailable" or "plan.md could not be parsed" | You're in the Copilot harness. Switch to **Local** and start a new chat |
| The agent edits files outside `app/` and `.github/upgrades/` | Restore them with `git restore <path>` before you commit |
| The agent offers extra work (Aspire, ARM64, reports) | Decline: it's out of scope |

More help: [Troubleshoot](../04-troubleshoot/).
