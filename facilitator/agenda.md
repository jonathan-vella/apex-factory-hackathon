# Two-day agenda

The challenge minutes are effort targets, not a serial schedule. ALZ-lite and the source assessment overlap C1/C3; SQL Managed Instance provisioning overlaps the start of C6; the MI link starts on Day 2 while C6 finishes.

## Pre-work

| When | Activity | Owner |
|---|---|---|
| T-14 | Preflight, access and Copilot-policy gate; confirm the roster and team subscriptions | Event owner, platform lead, members |
| T-14 to T-3 | Resolve access and quota blockers; grant the SQL MI directory identity its Graph read permissions after ALZ-lite is available and before C7 | Platform lead, directory administrator |
| T-3 | Deploy and validate datacenters, Arc onboarding, first migration assessment and legacy app | Members, platform lead |
| Before Day 1 | Stop idle VMs, check the room and projection, stage demo materials and publish this agenda | Event owner, coaches |

## Day 1

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Welcome, roles, roster lock and evidence walkthrough | Kickoff / event owner | Explain that the roster is fixed for the member average |
| 09:00–09:45 | Define the opportunity | C1 / teams | ALZ-lite deployment starts in parallel |
| 09:00–10:00 | Assess the source | C3 / members | Runs in parallel with C1 and the start of C2 |
| 09:45–11:45 | Secure the foundation | C2 / platform lead and teams | Coach's live portal ALZ demo opens C2; ALZ-lite and vending follow while C3 finishes |
| 11:45–12:30 | Choose target states | C4 / teams and members | Complete the ADRs and deferred-work register |
| 12:30–13:15 | Lunch break | — | — |
| 13:15–13:45 | APEX archetype demo | C5 / coach | Use the 30-minute script; show APEX's artifact/review flow and the `azd` deployment path |
| 13:45–14:45 | Deploy the CoE archetype | C5 / members | Adapt, preview, provision and document the deployed state |
| 14:45–16:15 | Modernize with GHCP, part 1 | C6 / members | MI provisioning starts in the background; do not deploy the app to App Service yet |
| 16:15–16:30 | Break | — | — |
| 16:30–16:45 | Day 1 check-out and evidence capture | Event owner, coaches | Day 1 deny-policy curveball is scheduled during C2; remove it after its evidence is signed off |

## Day 2

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Reconnect, review blockers and start the MI link | Platform lead, members | Start first thing; seeding overlaps the end of C6 |
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
- ALZ-lite deploys during C1 and C3. Members can reach the dev VM through Bastion without waiting for ALZ-lite.
- SQL MI provisioning starts while C6 begins on Day 1. The MI link starts at the beginning of Day 2, so automatic seeding runs while the final C6 work completes.
- If the MI or link misses the agenda window, do not skip the read-only replica checks or cut over under time pressure. The coach uses the Day 2 abort curveball and the team replans.
- Breaks are protected time. Move showcase discussion rather than silently extending the challenge time boxes.
