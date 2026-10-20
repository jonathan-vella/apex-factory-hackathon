---
title: "VS Code: troubleshoot"
description: What to paste when a task's build or checks don't pass.
sidebar:
  order: 5
---

Try these in order. Steps 1 and 3 diagnose first and change nothing; step 2 asks the agent to apply a fix.

## 1. Name the exact symptom, don't just say "it failed"

```text
Task <task-id>'s check is failing: <paste the exact error, failing check, or unexpected behavior>. Diagnose the cause before changing anything, and tell me what you find.
```

## 2. Check the three known gap areas

If the symptom involves startup wiring, notifications, or logging/telemetry, name the matching skill — this
is faster than general diagnosis. First run these searches, so you know which skill applies:

```powershell
git grep -n "new NotificationService" -- app
git grep -n -i -E "System\.Web|System\.Messaging|MessageQueue|Trace\.|Debug\.Write" -- app/ContosoUniversity
```

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

## 4. If `start_task` or the agent's tools fail outright

| Symptom | Fix |
|---|---|
| "internal LLM client unavailable" or "plan.md could not be parsed" | You're in the Copilot harness — switch to **Local** and start a new chat |
| "The Upgrade workflow tools aren't available" | Reload the window (**Developer: Reload Window**) and start a new chat |

## Still stuck after two attempts

Ask your coach, per the playbook's rule — don't spend the whole time box on one blocker.
