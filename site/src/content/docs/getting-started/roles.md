---
title: Roles
description: What a member, the team lead and a coach each do, and when.
sidebar:
  order: 4
---

There are three roles. Every attendee is a **member**. One member per team is also the **team lead**. **Coaches** support the teams but are not part of them.

## Member

Everyone on the team, the team lead included. A team is 3 to 5 people.

Each member has their own workload subscription and a member index, and works in their own repo. You:

- run the checks and deployments for your own subscription before the event: preflight by T-14, then your datacenter, the readiness check and `vm-dev01` by T-3,
- share your roster values with the team lead (see below),
- do the member challenges (C3, C5, C6, C7, C8 and C9) on your own, and the team challenges (C1, C2, C4 and C10) together with your team,
- keep your evidence in your own repo, on `main`. There is no shared team repo.

The steps are in [Member steps](../../deploy/member-steps/). Set up your repo first with [Set up your repo](../../deploy/set-up-your-repo/).

### Roster values

The team lead needs four values from each member to connect your subscription to the team's foundation: your workload subscription ID, your member index, your Microsoft Entra object ID and your work email. Share them privately with the team lead. Never put them in a repo, an issue or a channel that others can read.

## Team lead

A colleague your team nominates. One per team. The team lead is also a member and does everything above, on their own workload subscription.

On top of that, the team lead looks after the team's shared foundation:

1. **Before T-7:** collects the roster values from every member and gives each member a distinct member index from 1 to 20. Indexes 1 to 5 are enough for a team of five, with the team lead as 1.
2. **T-7:** deploys the foundation, which is the team's shared hub network, policies and central services. Asks someone with the Privileged Role Administrator role in your tenant to grant the SQL MI identity its Graph read.
3. **T-1:** vends every member, themselves included. Vending connects a member's subscription to the foundation. Only members whose readiness record a coach has approved are vended.
4. **Day one:** walks the team through the foundation in C2.

The team lead needs a second subscription for shared services and the Owner role at Tenant Root. [Requirements](../requirements/#accounts-and-access) lists both. The steps are in [Team lead steps](../../deploy/team-lead-steps/).

<details>
<summary>Why the team lead role exists</summary>

The foundation is shared, so one person builds it once for the team instead of every member building their own. It also needs rights that only a few people hold: Owner at Tenant Root and a Privileged Role Administrator for the Graph grant.

</details>

## Coach

Not a team member. A coach supports several teams. The coach:

- reviews your readiness record at T-3, before the team lead vends your subscription,
- gives the live portal demo of an Azure landing zone in C2 and the APEX archetype demo before C5,
- asks the policy questions in C2, signs off evidence and scores, and runs the curveballs,
- decides when and how to unblock a stuck member or team.

A coach doesn't do the work for the team. Ask your coach for help, not for the answer. Your coach is also your first contact at T-14 and T-3.

## Next

Go to [Deploy](../../deploy/) for the steps and the order they run in. Terms you don't know are in the [glossary](../../reference/glossary/).
