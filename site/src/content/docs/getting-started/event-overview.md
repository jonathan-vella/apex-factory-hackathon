---
title: Event overview
description: The two-day agenda and the T-14 and T-3 readiness gates.
sidebar:
  order: 1
---

The event runs over two days, plus pre-work before day one. Format: a team of members works through the day's challenges in parallel where the challenge is scoped to a member, and together where it's scoped to the team.

## Pre-work

Every member completes [C0: Ready to hack](../../challenges/c00-ready-to-hack/) before the event: preflight, datacenter, Arc onboarding and a first migration assessment. Two readiness gates apply:

- **T-14 (two weeks before):** `Test-Preflight.ps1` reports GO and you've confirmed the manual checks yourself. This is the last point where an access or quota problem can realistically be escalated and fixed before the event.
- **T-3 (three days before):** the datacenter deployed, `Test-Datacenter.ps1` green for every member (run before Arc onboarding, because Arc turns off the run commands it uses), Arc onboarded, the first assessment run and the legacy app healthy. A coach reviews every member's C0 output.

Missing either gate puts a member's start on day one at risk; coaches escalate gate misses to the event owner, not to the team. The roster locks at kickoff, so a member who can't get ready can still be swapped or dropped before then.

## Day one

The platform lead starts ALZ-lite at 09:00, while the team does C1; C1 needs no Azure access. After a coach's live portal ALZ demo, C2 continues with the Graph grant and vending while members assess the source in C3. C4 (choose target states) and C5 (the CoE archetype, after a coach's APEX demo) follow. C6 (Modernize the app) starts on day one and spans into day two. The [agenda](../../about/#agenda) has the times.

## Day two

The MI link starts at 08:30, as C7 task 1, so seeding overlaps the end of C6. C6 finishes, then C7 (migrate the data), C8 and C9 (validate and optimize) and C10 (package and operate) close out the event with a team showcase.

## Time boxes are pacing, not hard stops

Each challenge page states a time box to help you pace the day. The two real gates are T-14/T-3 before the event, and the end of each day during it — not each challenge's individual minutes.
