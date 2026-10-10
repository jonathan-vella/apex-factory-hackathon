---
title: Event overview
description: The two-day agenda and the T-14 and T-3 readiness gates.
---

The event runs over two days, plus pre-work before day one. Format: a team of members works through the day's challenges in parallel where the challenge is scoped to a member, and together where it's scoped to the team.

## Pre-work

Every member completes [C0: Ready to hack](../../challenges/c00-ready-to-hack/) before the event: preflight, datacenter, Arc onboarding and a first migration assessment. Two readiness gates apply:

- **T-14 (two weeks before):** every automated and manual preflight check green. This is the last point where an access or quota problem can realistically be escalated and fixed before the event.
- **T-3 (three days before):** the datacenter deployed, `Test-Datacenter.ps1` green for every member (run before Arc onboarding, because Arc turns off the run commands it uses), Arc onboarded, the first assessment run and the legacy app healthy.

Missing either gate puts a member's start on day one at risk; coaches escalate gate misses to the event owner, not to the team.

## Day one

M1 Foundation (C1, C2) runs first, with ALZ-lite deploying in the background while the team works through C1. M2 Assess and decide (C3, C4) and M3 Archetype (C5) follow. C6 (M4 Modernize the app) typically starts on day one and spans into day two.

## Day two

C6 finishes, then M5 Migrate the data (C7), M6 Validate and optimize (C8, C9) and M7 Package and operate (C10) close out the event with a team showcase.

## Time boxes are pacing, not hard stops

Each challenge page states a time box to help you pace the day. The two real gates are T-14/T-3 before the event, and the end of each day during it — not each challenge's individual minutes.
