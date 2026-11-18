# Two-day agenda (coach)

The challenge minutes are effort targets, not a serial schedule. The platform foundation is built before the event: ALZ-lite at Step 2 (T-7) and vending at Step 4 (T-1), so Day 1 opens with a 30-minute PowerPoint introduction by the tech lead, starts C1 at 09:00, and runs C2 as a 45-minute member challenge testing AI coding agents against repository and landing-zone guardrails on `vm-dev01`. SQL Managed Instance provisioning overlaps the start of C6, and the MI link starts on Day 2 at 08:30 while C6 finishes. The challenge totals are 10 challenges and 750 minutes.

Staff at least one coach per six attendees. Before kickoff, read the guide's [kickoff duties](guide.md#kickoff-and-event-days), [lifeline handout rules](guide.md#lifeline-handout) and [escalation table](guide.md#escalation). The [platform pipeline](platform-pipeline.md), [cost estimate](cost-estimate.md) and [cleanup](cleanup.md) are the operational references. Use **Lifelines**, **Curveballs** and **APEX demo script** in the Coach sidebar during the event.

## Before the event

| When | Activity | Owner |
|---|---|---|
| T-30 to T-14 | Event-owner setup: choose Path A (self-service teams) or Path B (lead-provisioned cohort, with 3-to-5-person breakout pods and pod leads when `n > 5`), tenant and subscription access, nominate the team lead, and book the Privileged Role Administrator for T-7 (see the [guide](guide.md#t-30-to-t-14-event-owner)) | Event owner, team lead |
| Step 1 (T-14) | Path A: repo setup and preflight; each member shares subscription ID, index, object ID and email privately with the team lead. Path B: team lead runs `Initialize-CohortRepos.ps1` and cohort `whatif`; students share GitHub usernames privately and accept repo invites | Team lead, members |
| Step 2 (T-7) | Team lead runs the `foundation` stage (ALZ-lite, pipeline run 1), then a Privileged Role Administrator runs the Graph grant for the SQL MI identity | Team lead, Privileged Role Administrator |
| Step 3 (T-3) | Path A: each member runs `whatif` and `member` (datacenter, `Test-Datacenter.ps1` before Arc, Arc onboarding). Path B: team lead runs `member` across the cohort. Everyone completes the portal migration assessment, `vm-dev01` Copilot setup and `factory/evidence/readiness/` | Team lead, members |
| Step 4 (T-1) | Team lead runs the `vending` stage (in batches such as `-f members=1-50` when `n > 60`): it stops at the first member who is not ready; earlier members are vended but not restarted, exempted or probed, and later members are not vended. Fix phase 1 or 2 failures and re-run; phase 3 failures name the members to rerun | Team lead |
| Before Day 1 | Start both VMs of every datacenter (idle ones may have been stopped), check the room and projection, stage demo materials and publish this agenda | Event owner, coaches |

## Day 1

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | 30-minute kickoff presentation (scenario, roles, challenges) and roster lock | Kickoff / tech lead and event owner | Include two or three full-ALZ slides or a short recording to contrast the production pattern with ALZ-lite; no separate live ALZ demo. The owner supplies this material before the event. The roster locks here |
| 09:00–09:45 | Define the opportunity (CAF Strategy) | C1 / teams | Everyone starts here, team lead included. C1 needs no Azure access |
| 09:45–10:30 | Secure, AI-ready foundation (AI guardrails test) | C2 / members | Each member tests an AI coding agent against APEX's Bicep baseline (`iac-security-baseline.md`) and ALZ `Deny` policies in `rg-spoke`, checks exemptions and runs `Test-Connectivity.ps1` |
| 10:15 (inside C2) | Day 1 policy curveball | Coach, team lead | Follow **Curveballs** in the Coach sidebar; capture the denial and decision, then remove only the exercise assignment before C5 at 13:45 |
| 10:30–11:30 | Assess the source | C3 / members | Each member runs the Upgrade agent assessment and plan on `vm-dev01` and triages the Arc SQL assessment findings |
| 11:30–12:15 | Choose target states | C4 / teams | Complete `decisions-and-register.md` in the team/pod lead's repo |
| 12:15–13:15 | Lunch break | — | — |
| 13:15–13:45 | APEX archetype demo | C5 / coach | Use the 30-minute script; show APEX's artifact/review flow and the `azd` deployment path |
| 13:45–14:45 | Deploy the CoE archetype | C5 / members | Adapt, preview, provision and document the deployed state |
| 14:45–16:15 | Modernize with GitHub Copilot, part 1 | C6 / members | MI provisioning starts in the background; do not deploy the app to App Service yet |
| 16:15–16:30 | Break | — | — |
| 16:30–16:45 | Day 1 check-out and evidence capture | Event owner, coaches | If the Day 1 deny-policy curveball ran during C2, confirm `curveball-allowed-locations` was removed before C5 started. Leave both VMs running |

## Day 2

| Time | Activity | Challenge / owner | Notes |
|---|---|---|---|
| 08:30–09:00 | Reconnect, check both VMs are running and the Graph grant is done, then start the MI link | Team lead, members | The link is C7 requirements 1 and 2 (prepare the source, then start the link), started early so seeding overlaps the end of C6. Requirements 1 and 2 count toward C7's 120 minutes, but the wait of up to 10 minutes while the link is created overlaps C6 and doesn't count |
| 09:00–10:30 | Modernize with GitHub Copilot, part 2 | C6 / members | Complete the 180-minute total across both days |
| 10:30–12:30 | Migrate and go live | C7 / members | About 100 minutes of C7's 120-minute effort remain after the early link setup. This window includes seeding slack; do not skip go/no-go. Trigger the abort curveball at go/no-go |
| 12:30–13:15 | Lunch break | — | — |
| 13:15–14:00 | Validate the pattern | C8 / members | Smoke, load, security (`acceptance.json`), upload, notification and telemetry checks on `vm-dev01` |
| 14:00–15:00 | Optimize the database with GitHub Copilot | C9 / members | Query Store `baseline` vs `after` and 5 `.sql` fix scripts |
| 15:00–15:15 | Break | — | — |
| 15:15–16:15 | Package, hand over and review AI readiness | C10 / teams | Complete `reusable-asset/` and `handover-and-ai-review.md` in the team/pod lead's repo |
| 16:15–17:00 | Showcase and close | Event owner, coaches, teams | 5-minute team showcases and owner follow-ups |

## Planned overlaps and controls

- ALZ-lite is deployed at Step 2 (T-7) and every member is vended at Step 4 (T-1), so the foundation and spokes are already in place when Day 1 begins.
- SQL MI provisioning starts while C6 begins on Day 1. The MI link starts at 08:30 on Day 2 (C7 requirements 1 and 2), so automatic seeding runs while the final C6 work completes.
- Keep `vm-dev01` running from Day 1 kickoff to the end of the event, and keep `vm-app01` running until the link is removed. Stop VMs only in the gaps before the event (not during the Step 4 vending, which restarts and probes them) and after the event.
- If the MI or link misses the agenda window, do not skip the read-only replica checks or cut over under time pressure. The coach uses the Day 2 abort curveball and the team replans.
- The morning schedule on Day 1 is sequential (kickoff 08:30, C1 09:00, C2 09:45, C3 10:30, C4 11:30), so the team lead and members move through C1 to C4 together without splitting tracks.
- Teams take a 10 to 15 minute break inside their own time box when needed. Move showcase discussion rather than silently extending the challenge time boxes.
