---
title: Pre-work
description: What to do before the event, which is Prerequisites and C0.
sidebar:
  order: 3
---

Pre-work is [Prerequisites](../prerequisites/) (accounts, tools, your repo with the kit imported) followed by [C0: Ready to hack](../../challenges/c00-ready-to-hack/). T-14 is 14 days before day one of the event and T-3 is 3 days before it. Complete Prerequisites and C0's preflight by T-14, and give the event owner the values for the roster (see Prerequisites). By T-3: the datacenter is deployed, `Test-Datacenter.ps1` passes for you (run before Arc onboarding), `vm-app01` is connected to Azure Arc, your first migration assessment has run, the legacy app is healthy, and you have a fully set up `vm-dev01` (C0 task 7), with Copilot working in VS Code. A coach reviews your output, and at T-1 your platform lead vends your subscription. The [event overview](../event-overview/#pre-work) has all the dates.

If you're the platform lead, you still complete your own C0 like every other member. Enter your shared services subscription when `Initialize-Settings.ps1` asks (see Prerequisites), so preflight also checks your Tenant Root rights at T-14. The shared services work comes in two runs: you deploy ALZ-lite at T-7, with a Privileged Role Administrator for the Graph grant, and you vend every member at T-1, after the coach's C0 review. [C2](../../challenges/c02-secure-ai-ready-foundation/#before-the-event) has the steps.

Next: [Prerequisites](../prerequisites/).
