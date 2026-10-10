# Scoreboard

Copy one scoreboard per team. Lock the roster at kickoff and enter every member, even if they later leave or miss a challenge. The rubric controls evidence, partial credit, lifeline caps and bonus awards.

## Team summary

| Team | C1 / 10 | C2 / 35 | C4 / 15 | C10 / 20 | Team base / 80 | Team bonus | Coach sign-off |
|---|---:|---:|---:|---:|---:|---:|---|
| `<team>` |  |  |  |  |  |  |  |

## Member scores

| Member | C0 / 10 | C3 / 15 | C4 / 10 | C5 / 15 | C6 / 30 | C7 / 20 | C8 / 10 | C9 / 10 | Member base / 120 | Member bonus | Lifelines used | Coach sign-off |
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
Team base = C1 + C2 + team portion of C4 + C10                 (maximum 80)
Member base = C0 + C3 + member portion of C4 + C5 + C6 + C7
              + C8 + C9                                       (maximum 120 per member)
Average member base = sum(member base for kickoff roster) / roster size
Awarded bonus = min(30, team bonus + average member bonus)
Team score = team base + average member base + awarded bonus  (maximum 230)
```

Rank teams by team score. Teams with the same score share the rank.

Enter C4's team and member portions in their separate columns. Record lifeline caps in the affected member/challenge cell, for example `15/30 — L3-servicebus` for C6, or `10/20 — known-good image` or `10/20 — L5-cutover` for C7. Store evidence in the team's repository and do not paste secrets or tenant, subscription or object IDs into this public scoreboard.
