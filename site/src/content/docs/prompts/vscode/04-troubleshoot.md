---
title: "VS Code: troubleshoot"
description: What to paste when a task's build or checks don't pass.
sidebar:
  label: Troubleshoot (C6)
  order: 5
---

Used in [C6, requirements 2 and 3](../../../challenges/c06-modernize-with-ghcp/#requirements).

**Validated on:** 2026-10-31 (documentation consistency with C6 and the playbook's agent, model and recovery guidance; no new runtime test).

Try these in order. Step 1 diagnoses before changing anything; steps 2 and 3 can change files; step 4 fixes the tooling.

## Before you send

For **C6 requirements 2 and 3**, open `C:\src\factory` on `vm-dev01`, on your app work branch. Use plain **Agent** for diagnosis and gap fixes, harness **Local**, and a balanced execution model from the playbook's Models table. Return to **Upgrade** only to resume an actual agent task.

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
| `System.Messaging` or `MessageQueue` remains; a controller creates `NotificationService` or a Service Bus client; toasts don't appear | `notification-service-di` |
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
