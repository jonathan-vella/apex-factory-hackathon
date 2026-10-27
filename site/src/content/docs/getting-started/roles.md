---
title: Roles
description: Platform lead, members, coach and event owner, and who does what.
sidebar:
  order: 5
---

## Platform lead

One per team. Holds the shared services subscription and the Owner role at Tenant Root (the top management group of your tenant), which is needed to create management groups and move subscriptions. Deploys ALZ-lite at T-7 (see [C2](../../challenges/c02-secure-ai-ready-foundation/#before-the-event)), asks someone with the Privileged Role Administrator role in your tenant (the event owner books them for T-7) to run `Grant-SqlMiDirectoryRead.ps1` right after it, and at T-1 vends every member, themselves included, restarts their VMs, records the exemptions and runs the connectivity probes. Vending connects a member's subscription to the team's shared foundation. On day one the platform lead walks the team through all of it in C2.

The platform lead is also a student. They hold their own workload subscription and a member index, do C0 like everyone else, and do every member challenge (C0, C3, C5, C6, C7, C8, C9) on it, as well as the team challenges (C1, C2, C4, C10). C4 has a team part and a member part.

## Members

Everyone else on the team: teams have three to five people, platform lead included. Each member has their own workload subscription and a member index (1 to 20), runs the member challenges independently, and joins the team challenges together with the rest of the team. Evidence goes in each member's own repo, on `main`; there is no shared team repo. C1 sets it up and gives the rule for where to commit it.

## Coach

Not a team member. Gives the live portal ALZ demo in C2 and the APEX archetype demo before C5, reviews your C0 output at T-3 (before your platform lead vends you), asks the policy questions in C2, signs off evidence and scores, runs the curveballs, relays your member index (the event owner assigns it), decides when and how to unblock a stuck member or team, and answers the kind of question a member genuinely can't resolve alone. A coach doesn't do the work for the team: ask your coach for help, not for the answer. Your coach is also your first contact at T-14 and T-3.

## Event owner

The partner practice lead who runs the event. Sets the dates, region and team size, builds the roster, captures every member's subscription ID, index, object ID and email at T-14, names the platform leads, books the Privileged Role Administrator for T-7, handles escalations that coaches pass up (such as a gate missed at T-14 or T-3), signs off the final scores and owns cleanup. If you can't reach your coach, contact the event owner through the escalation channel published with the agenda.

## Where to go next

Continue with [Prerequisites](../prerequisites/).
