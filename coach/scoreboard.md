# Scoreboard and badges (coach)

Copy one scoreboard per team. Lock the roster at kickoff and enter every member, even if they later leave or miss a challenge. The [rubric](../facilitator/scoring-rubric.md) controls evidence and base points; the scoring rules, lifeline caps and bonus awards are below.

## Team summary

| Team | C1 / 10 | C4 / 15 | C10 / 20 | Team base / 45 | Team bonus | Coach sign-off |
|---|---:|---:|---:|---:|---:|---|
| `<team>` |  |  |  |  |  |  |

## Member scores

| Member | C2 / 15 | C3 / 15 | C4 / 10 | C5 / 15 | C6 / 30 | C7 / 20 | C8 / 10 | C9 / 10 | Member base / 125 | Member bonus | Lifelines used | Coach sign-off |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| `<member 1>` |  |  |  |  |  |  |  |  |  |  |  |  |
| `<member 2>` |  |  |  |  |  |  |  |  |  |  |  |  |
| `<member 3>` |  |  |  |  |  |  |  |  |  |  |  |  |
| `<member 4>` |  |  |  |  |  |  |  |  |  |  |  |  |
| `<member 5>` |  |  |  |  |  |  |  |  |  |  |  |  |

Remove unused member rows only before kickoff, then freeze the roster. Leave a zero for missing evidence; do not remove that member from the average.

## Badge and bonus record

| Bonus evidence | Eligible points | Awarded | Evidence link / location | Coach |
|---|---:|---:|---|---|
| Challenge bonus tasks (C2, C3, C5, C6, C7, C8, C10) | Up to the challenge-page maxima |  |  |  |
| Zero public backend endpoints | 5 |  |  |  |
| Policy clean | 5 |  |  |  |
| Rollback ready | 5 |  |  |  |
| Trust but verify | 5 |  |  |  |
| Cost guardian | 5 |  |  |  |
| Reusable-asset contributor | 5 |  |  |  |
| **Total bonus** | **30 maximum** |  |  |  |

## Formula

```text
Team base = C1 + team portion of C4 + C10                     (maximum 45)
Member base = C2 + C3 + member portion of C4 + C5 + C6 + C7
              + C8 + C9                                       (maximum 125 per member)
Average member base = sum(member base for kickoff roster) / roster size
Awarded bonus = min(30, team bonus + average member bonus)
Team score = team base + average member base + awarded bonus  (maximum 200)
```

Rank teams by team score. Teams with the same score share the rank.

Enter C4's team and member portions in their separate columns. Record lifeline caps in the affected member/challenge cell, for example `15/30 — L3-servicebus` for C6, or `10/20 — known-good image` or `10/20 — L5-cutover` for C7. Store evidence in each member's own repo under `factory/evidence/`, and do not paste secrets or tenant, subscription or object IDs into this public scoreboard. Score team items once per team, from the team lead's copy.

## Scoring rules

- Lock the roster at kickoff. The member average includes every person on that roster; a missing or unverified item scores zero. Do not remove an absent member from the denominator after kickoff.
- Award team evidence once per team. Award member evidence separately for each member.
- Base team score = team base points + the arithmetic mean of member base points. The maximum base score is 170.
- Score each evidence row independently. Full points require the listed evidence. Award half the row value, rounded down, when evidence is present but one verifiable subcomponent is incomplete; award zero when evidence is absent, unverified or materially incorrect. Record the reason for partial credit. Never exceed a row's maximum or move unused points between rows.
- Lifelines cap the affected challenge only; later challenges remain eligible. Record the branch or image in the scoreboard. C6 use of L1, L2, L3, L4 caps C6 at **15 of 30 member points**. C7 use of L5, or of the known-good image at go-live, caps C7 at **10 of 20 member points**. Ordinary hints and coach discussion do not trigger a cap.
- Challenge bonus tasks and badges draw from one bonus allowance per team, capped at **30 points**. A badge is worth 5 team bonus points, once per team. Challenge bonus tasks are awarded to the scope of their challenge and retain the challenge-page maxima. Award bonuses in the order of the scoring sections below (Badges, then Challenge bonus tasks) until the team reaches the cap. Once a team has reached it, further eligible bonus evidence is recorded but adds no points.
- Rank teams by team score. Teams with the same score share the rank.
- Team score = team base points + average member base points + awarded team bonus + average awarded member bonus, with combined bonus capped at 30. The scoreboard shows the components separately.
- Coaches sign off evidence and the event owner resolves scoring disagreements against these rules and the rubric. Coaches read each member's own repo (evidence is in `factory/evidence/cNN/`). Score team items once per team, from the team lead's copy; the other members' copies must match it. Redact secrets and tenant, subscription and object IDs before sharing evidence publicly.

## Badges

Each badge adds 5 team bonus points when its evidence is signed off. Badges share the team's 30-point bonus cap with challenge bonus tasks.

| Badge | Criteria | Evidence |
|---|---|---|
| Zero public backend endpoints | SQL MI, Blob, Service Bus, Key Vault and ACR are private-only; only the documented web front end and telemetry ingestion are public exceptions | C8 security check with the commands or portal views used |
| Policy clean | Kit Deny policies have no unapproved violations on the archetype resources; the documented datacenter exemptions are not counted as unapproved violations | Policy compliance evidence and the reviewed exemption register |
| Rollback ready | The team can explain the pre-cutover abort, the writable MI copy trap and the safe reseed plan | Committed cutover/rollback runbook, with C7 abort evidence if the curveball was triggered |
| Trust but verify | AI-produced changes are reviewed by a person and the relevant build, test or runtime checks are recorded | Task commits and check output linked from the evidence |
| Cost guardian | Team records the event cost, stops idle datacenter VMs outside the event days (never `vm-dev01` during the event) and accounts for the MI schedule and budget | Cost worksheet and shutdown/schedule evidence |
| Reusable-asset contributor | Another team could use the packaged asset without undocumented tribal knowledge | C10 asset, README and handover reference |

## Challenge bonus tasks

Use the bonus opportunities on the challenge pages: C2, C3, C5, C6, C7 and C8 offer up to 5 points each; C10 offers up to 10. C1, C4 and C9 have no bonus task. Award only documented evidence and apply the shared 30-point ceiling.

The C7 bonus (clean reseed after an abort) applies only to a real, unplanned abort. The coach-staged Day 2 abort is part of the event and earns no bonus.
