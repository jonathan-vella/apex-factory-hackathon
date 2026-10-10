# Two-day agenda

The challenge minutes are effort targets, not a serial schedule. On Day 1 the platform lead starts ALZ-lite at 09:00 and it deploys while the team does C1. SQL Managed Instance provisioning overlaps the start of C6, and the MI link starts on Day 2 at 08:30 while C6 finishes. The challenge totals don't change: 11 challenges, 975 minutes.

## Pre-work

| When | Activity | Owner |
|---|---|---|
| T-30 to T-14 | Event-owner setup: draft roster, member indexes, platform lead and team-repo creator, tenant and subscription access, Privileged Role Administrator booking (see the [guide](guide.md#t-30-to-t-14-event-owner)) | Event owner |
| T-14 | Preflight, access and Copilot-policy gate; confirm the draft roster and team subscriptions | Event owner, platform lead, members |
| T-14 to T-3 | Resolve access and quota blockers; confirm the Privileged Role Administrator is booked for day one (the Graph grant for the SQL MI identity, run in C2 after ALZ-lite) | Platform lead, directory administrator |
| T-3 | Deploy datacenters, validate them with `Test-Datacenter.ps1` while the VMs run, then Arc onboarding and the first migration assessment; a coach reviews every member's C0 output | Members, platform lead, coaches |
| Before Day 1 | Start both VMs of every datacenter (idle ones may have been stopped), check the room and projection, stage demo materials and publish this agenda | Event owner, coaches |

## Day 1

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Welcome, roles, roster lock and evidence walkthrough | Kickoff / event owner | The roster locks here, after the T-3 review. The member average uses this roster |
| 09:00–09:45 | Define the opportunity | C1 / teams | At 09:00 the platform lead starts ALZ-lite (C2 task 3, about 10 minutes) and then joins C1. C1 needs no Azure access |
| 09:45–10:15 | Live portal ALZ demo | C2 task 2 / coach | Everyone watches. The demo is part of C2's 120 minutes |
| 10:15–11:45 | Secure the foundation | C2 / platform lead and teams | The platform lead and the Privileged Role Administrator run the Graph grant (C2 task 4), then the platform lead vends every member. Members record exemptions and run the probes once vended |
| 10:15–11:15 | Assess the source | C3 / members | Members work while the platform lead vends. The platform lead's own C3 follows vending and overlaps C4 |
| 11:45–12:30 | Choose target states | C4 / teams and members | Complete the ADRs and deferred-work register |
| 12:30–13:15 | Lunch break | — | — |
| 13:15–13:45 | APEX archetype demo | C5 / coach | Use the 30-minute script; show APEX's artifact/review flow and the `azd` deployment path |
| 13:45–14:45 | Deploy the CoE archetype | C5 / members | Adapt, preview, provision and document the deployed state |
| 14:45–16:15 | Modernize with GHCP, part 1 | C6 / members | MI provisioning starts in the background; do not deploy the app to App Service yet |
| 16:15–16:30 | Break | — | — |
| 16:30–16:45 | Day 1 check-out and evidence capture | Event owner, coaches | Day 1 deny-policy curveball is scheduled during C2; remove it after its evidence is signed off. Leave both VMs running |

## Day 2

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Reconnect, check both VMs are running and the Graph grant is done, then start the MI link | Platform lead, members | The link is C7 task 1, started early so seeding overlaps the end of C6. The time counts toward C7's 120 minutes |
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
- ALZ-lite deploys during C1. Members can reach the dev VM through Bastion without waiting for ALZ-lite.
- SQL MI provisioning starts while C6 begins on Day 1. The MI link starts at 08:30 on Day 2 (C7 task 1), so automatic seeding runs while the final C6 work completes.
- Keep `vm-dev01` running from Day 1 kickoff to the end of the event, and keep `vm-app01` running until the link is removed. Stop VMs only in the pre-work gaps and after the event.
- If the MI or link misses the agenda window, do not skip the read-only replica checks or cut over under time pressure. The coach uses the Day 2 abort curveball and the team replans.
- Day 1 from 09:00 to 12:30 holds more challenge minutes than clock time, because C1, C2, C3 and C4 overlap. The platform lead carries the most overlap, so coaches protect the C4 hour for the ADRs and don't add work.
- The agenda has no spare minutes for a break on Day 1 before 12:30 or between 13:15 and 16:15, or on Day 2 before 12:30. Teams take a 10 to 15 minute break inside their own time box. Move showcase discussion rather than silently extending the challenge time boxes.
