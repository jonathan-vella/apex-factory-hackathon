---
title: "Copilot App: troubleshoot"
description: What to paste when a task's build or checks don't pass.
sidebar:
  order: 5
---

Try these in order. Each is read-only diagnosis first — none of them changes anything until you ask for a fix.

## 1. Name the exact symptom, don't just say "it failed"

```text
Task <task-id>'s check is failing: <paste the exact error, failing check, or unexpected behavior>. Diagnose the cause before changing anything, and tell me what you find.
```

## 2. Check the three known gap areas

If the symptom involves startup wiring, notifications, or logging/telemetry, name the matching skill — this
is faster than general diagnosis:

| Symptom | Skill |
| --- | --- |
| `System.Web`, `Global.asax`, or `App_Start` code still present; CSS/JS doesn't load | `aspnet-startup-migration` |
| A controller still creates its own `NotificationService` or Service Bus client; toasts don't appear | `notification-service-di` |
| `Trace`/`Debug` calls left; telemetry doesn't reach Application Insights | `trace-to-opentelemetry` |

```text
Use the <skill-name> skill. Scope: app/ContosoUniversity only.
```

## 3. Check you're not in the wrong scope

```powershell
git status --short -- . ':!app' ':!.github/upgrades'
```

Must print nothing. If it prints anything, the agent touched something outside its scope:

```text
Restore everything outside app/ContosoUniversity and .github/upgrades to its last committed state, then re-run the task's validation.
```

## 4. If the Upgrade agent's tools aren't responding at all

Not a task-content problem — an MCP/session problem. Don't keep retrying in the same chat:

1. Start exactly one new chat (not several in parallel).
2. If that also fails, fully quit and restart the Copilot app, then try once more in a single new chat.
3. Still failing: switch to the [VS Code track](../../vscode/01-assess-and-plan/) and resume there. The kit's
   playbook already documents this as a known limitation of the Copilot app, with VS Code as the validated
   fallback — this isn't a sign you did something wrong.

## Still stuck after two attempts

Ask your coach, per the playbook's rule — don't spend the whole time box on one blocker.
