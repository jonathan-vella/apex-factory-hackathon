# B12: Build the facilitator kit

| Field | Value |
|---|---|
| Milestone | P4 Content |
| Type | Both |
| Depends on | B11 |
| Unblocks | B13 |
| Effort | 2–3 days |
| Cost | None. The cleanup script is validated for real in B13 |
| Teardown | Not applicable: nothing is deployed |
| PRD | §3 Coach, Event owner; §5 Curveballs, Scoring, Badges; §7 Deliverables 3 |

## Outcome

- `facilitator/` has everything an event owner and coaches need to run the event without the author: guide, agenda, scoring rubric (the single source of truth), curveballs, badges, scoreboard, APEX demo script, cost estimate and cleanup.
- `scripts/Remove-FactoryEnvironment.ps1` cleans up a member's or team's Azure resources, including the re-run traps.

## Before you start

1. B11 is closed. `npm run check` passes on `main`.
2. Read the PRD §5 scoring rules and the challenge pages from B11.

## Requirements

### Guide and agenda

1. `facilitator/guide.md`: roles (event owner, coach, platform lead, member), the timeline from T-14 to after the event (preflight, datacenter by T-3, kickoff, the two days, cleanup), room and tenant logistics, how to hand out lifelines, how to sign off evidence, and escalation for blockers (quota, CSP roles, Copilot policies).
2. `facilitator/agenda.md`: a two-day agenda built on the B11 time boxes and the spike timings, showing the planned overlaps: ALZ deploys during C1 and C3; the MI provisions during C6 on Day 1; the MI link starts first thing on Day 2 so seeding overlaps the end of C6. Include breaks, the live portal ALZ demo by a coach at the start of C2 (no script: the coach runs it in their own tenant), the APEX demo, the curveball slots and the showcase.
3. `facilitator/event-owner.md`: how a partner creates their own copy of the kit from the template, what to change (branding, dates, region), and how to keep it current with `versions.md`. Template copies don't reliably include the `lifeline/*` branches, so the guide says members fetch them from the upstream repo (as in `coach/lifelines.md`), or how a partner mirrors them into their own copy (fetch each branch from upstream and push it) and checks them with `git ls-remote`.

### Scoring

4. `facilitator/scoring-rubric.md` is the single source of truth for points. For each challenge: the evidence items, points per item summing to the B11 contract (80 team, 120 member, 200 base), and partial-credit rules.
5. Scoring rules: rosters lock at kickoff, and the member average uses the kickoff roster; team score = team points + the average of member points; a lifeline caps that challenge's points (state the cap) but keeps later challenges eligible; bonus up to 30 points.
6. Badges (PRD §5), each with its criteria, evidence and bonus points: zero public endpoints, policy clean, rollback ready, trust but verify, cost guardian, reusable-asset contributor.
7. `facilitator/scoreboard.md`: a scoreboard template (Markdown table per team and member, one column per challenge, lifelines and badges) that a coach fills in, with the formulas written out.
8. Add a check to `scripts/check-content-invariants.mjs` that the rubric's per-challenge point totals match the challenge contract.

### Curveballs

9. `facilitator/curveballs.md`, one per day, each with the trigger time, exactly what the coach does, what teams must do, the evidence and points, and how to reverse it after the event:
   - Day 1: a new deny policy lands mid-build. Choose a policy that the golden path already complies with but a shortcut would break, and give the assignment command at `mg-factory-corp`.
   - Day 2: the go/no-go check on the read-only replica fails, so the team aborts and re-plans the cutover (the abort path from B07).

### APEX demo

10. `facilitator/apex-demo.md`: a 30-minute demo script for the event deliverer: what APEX is, how the archetype was built (steps 1–5 with the challenger reviews), and a live Deploy of the archetype. Timings per section and what to say.
11. 🧑 HUMAN: the owner records the demo as the fallback video, and gives the executor the link to put in the script.

### Cost

12. `facilitator/cost-estimate.md`: cost per member and per team at list price with AHB on, for the datacenter (running and stopped), the foundation (ALZ-lite in the shared services subscription), the archetype and the whole event (pre-work from T-3, two days, cleanup the day after), from the runbook estimates and the B04–B10 actuals. Show what turning AHB off adds. Say which prices were checked and when.

### Cleanup

13. `scripts/Remove-FactoryEnvironment.ps1` (attendee script conventions) removes a member's resources (`-Scope Member`: datacenter, spoke and archetype) or a team's platform resources (`-Scope Team`: the ALZ-lite resources in the shared services subscription, the policy assignments, exemptions, budgets and the kit's management groups, after moving the subscriptions back under Tenant Root or a management group the event owner names). It handles the re-run traps: purges soft-deleted Key Vaults, waits for the SQL MI virtual cluster to release `snet-sqlmi` before deleting the VNet, and removes Arc resources. It lists everything it will delete and asks for confirmation unless `-Force` is passed. It never deletes subscriptions, management groups the kit didn't create, or resource groups the kit didn't create.
14. `facilitator/cleanup.md`: when and how to run it, and how to check nothing billable is left.

## Deliverables

- `facilitator/guide.md`, `agenda.md`, `event-owner.md`, `scoring-rubric.md`, `scoreboard.md`, `curveballs.md`, `apex-demo.md`, `cost-estimate.md`, `cleanup.md`.
- `scripts/Remove-FactoryEnvironment.ps1`.
- `scripts/check-content-invariants.mjs` updated.

## Verify

```powershell
Invoke-ScriptAnalyzer -Path scripts/Remove-FactoryEnvironment.ps1
Get-Help scripts/Remove-FactoryEnvironment.ps1 -Examples
npm run check
```

- PSScriptAnalyzer is clean, and the content checks pass, including the rubric total check.

## Done when

- [ ] Every facilitator file exists and matches the B11 contract.
- [ ] The rubric totals are enforced by the content checks.
- [ ] The cleanup script exists and passes static checks.
- [ ] The demo recording link is in the demo script.

## Commit message

```text
docs: add the facilitator kit
```

## Stop and ask if

- The spike timings don't fit the two-day agenda.
- The rubric can't match the B11 contract without changing a challenge's points.

## Notes and traps

- **Facilitator files are public,** like `coach/` (PRD §2). Don't put tenant details or real names in them.
- **Cleanup safety:** match resources by the kit's names and the member index, never by wildcard across the subscription.
