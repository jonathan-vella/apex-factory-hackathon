# Two-day agenda

The challenge minutes are effort targets, not a serial schedule. The platform foundation is built before the event: ALZ-lite at T-7 and vending at T-1, so Day 1 starts at C1 for everyone and C2 verifies and explains what already exists. SQL Managed Instance provisioning overlaps the start of C6, and the MI link starts on Day 2 at 08:30 while C6 finishes. The challenge totals don't change: 10 challenges, 825 minutes. The readiness check before the event has no points and no minutes in that total.

## Before the event

| When | Activity | Owner |
|---|---|---|
| T-30 to T-14 | Event-owner setup: team size, tenant and subscription access, Privileged Role Administrator booking for T-7, and each team nominates its team lead (see the [guide](guide.md#t-30-to-t-14-event-owner)) | Event owner |
| T-14 | Preflight, access and Copilot-policy gate; each member shares their subscription ID, index, object ID and email privately with the team lead; confirm the team subscriptions | Team lead, members |
| T-7 | Team lead runs the `foundation` stage (ALZ-lite, pipeline run 1), then a Privileged Role Administrator runs the Graph grant for the SQL MI identity | Team lead, directory administrator |
| T-3 | Each member does the readiness check in their own repo: the `whatif` and `member` stages (preflight, datacenter, `Test-Datacenter.ps1` while the VMs run, then Arc onboarding), then the first migration assessment and `vm-dev01` setup with a check that Copilot works in VS Code through Bastion; a coach approves every member's readiness record (see the [readiness gate](../coach/readiness.md)) | Members, coaches |
| T-1 | Team lead runs the `vending` stage (pipeline run 2): it vends every approved member in order, restarts the VMs, records the exemptions and runs the connectivity probes. Only coach-approved readiness records enter it, and it comes after `vm-dev01` setup | Team lead |
| Before Day 1 | Start both VMs of every datacenter (idle ones may have been stopped), check the room and projection, stage demo materials and publish this agenda | Event owner, coaches |

## Day 1

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Welcome, roles, roster lock and evidence walkthrough | Kickoff / event owner | The roster locks here, after the T-3 review and the T-1 vending. The member average uses this roster |
| 09:00–09:45 | Define the opportunity | C1 / teams | Everyone starts here, team lead included. C1 needs no Azure access |
| 09:45–10:15 | Live portal ALZ demo | C2 requirement 2 / coach | Everyone watches. The demo is part of C2's 120 minutes |
| 10:15–11:45 | Verify and explain the foundation | C2 / team lead and teams | The team lead walks the team through ALZ-lite, the Graph grant and vending (C2 requirements 3 to 5), and the coach asks about the core policies (the members' questions go in a 10 minute slot at 11:15, when C3 ends). Each member checks their exemptions and re-runs the probes (requirements 6 and 7, about 15 minutes) at a clean point in C3 |
| 10:15–11:15 | Assess the source | C3 / members | Members work while the team lead leads the C2 walk-through. The team lead's own C3 follows it and overlaps C4 |
| 11:45–12:30 | Choose target states | C4 / teams and members | Complete the ADRs and deferred-work register |
| 12:30–13:15 | Lunch break | — | — |
| 13:15–13:45 | APEX archetype demo | C5 / coach | Use the 30-minute script; show APEX's artifact/review flow and the `azd` deployment path |
| 13:45–14:45 | Deploy the CoE archetype | C5 / members | Adapt, preview, provision and document the deployed state |
| 14:45–16:15 | Modernize with GHCP, part 1 | C6 / members | MI provisioning starts in the background; do not deploy the app to App Service yet |
| 16:15–16:30 | Break | — | — |
| 16:30–16:45 | Day 1 check-out and evidence capture | Event owner, coaches | The Day 1 deny-policy curveball runs in C2 at 11:25 and comes off after its evidence is signed off, before C5 starts at 13:45: confirm it's gone. Leave both VMs running |

## Day 2

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Reconnect, check both VMs are running and the Graph grant is done, then start the MI link | Team lead, members | The link is C7 requirements 1 and 2 (prepare the source, then start the link), started early so seeding overlaps the end of C6. Requirements 1 and 2 count toward C7's 120 minutes, but the wait of up to 10 minutes while the link is created overlaps C6 and doesn't count |
| 09:00–10:30 | Modernize with GHCP, part 2 | C6 / members | Complete the 180-minute total across both days |
| 10:30–12:30 | Migrate and go live | C7 / members | Validate the read-only replica, go/no-go, cutover and app checks; trigger the abort curveball at go/no-go |
| 12:30–13:15 | Lunch break | — | — |
| 13:15–14:00 | Validate the pattern | C8 / members | Smoke, load, security, upload, notification and telemetry checks |
| 14:00–15:00 | Optimize the database with GHCP | C9 / members | Query Store before and after |
| 15:00–15:15 | Break | — | — |
| 15:15–16:15 | Package, hand over and review AI readiness | C10 / teams | Complete the handover and gap register |
| 16:15–17:00 | Showcase, scoring and close | Event owner, coaches, teams | Sign off evidence, apply the 30-point bonus ceiling and list owner follow-ups |

## Planned overlaps and controls

- The C2 portal ALZ demo is live and coach-led in the coach's own tenant; it has no kit deployment script.
- ALZ-lite is deployed at T-7 and every member is vended at T-1, so nothing deploys in C1 or C2. Members reach the dev VM through Bastion either way.
- SQL MI provisioning starts while C6 begins on Day 1. The MI link starts at 08:30 on Day 2 (C7 requirements 1 and 2), so automatic seeding runs while the final C6 work completes.
- Keep `vm-dev01` running from Day 1 kickoff to the end of the event, and keep `vm-app01` running until the link is removed. Stop VMs only in the gaps before the event (not during the T-1 vending, which restarts and probes them) and after the event.
- If the MI or link misses the agenda window, do not skip the read-only replica checks or cut over under time pressure. The coach uses the Day 2 abort curveball and the team replans.
- Day 1 from 09:00 to 12:30 holds more challenge minutes than clock time, because C1, C2, C3 and C4 overlap. The team lead carries the most overlap (the C2 walk-through, then their own C3), so coaches protect the C4 hour for the ADRs and don't add work.
- The agenda has no spare minutes for a break on Day 1 before 12:30 or between 13:15 and 16:15, or on Day 2 before 12:30. Teams take a 10 to 15 minute break inside their own time box. Move showcase discussion rather than silently extending the challenge time boxes.
