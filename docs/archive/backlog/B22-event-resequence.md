# B22: Re-sequence the event: the platform lead deploys ALZ-lite and vending before the event

| Field | Value |
|---|---|
| Issue | #135 |
| Milestone | P6 Platform automation |
| Type | Both |
| Depends on | B18 |
| Unblocks | The CoE archetype with Actions (later) |
| Effort | 4–6 days elapsed, mostly owner decisions and page rewrites |
| Cost | About $218 more per team for the firewall running from T-7 (216 hours at $1.30, against 48 hours on Day 1). The owner accepted this on 2026-10-26; the $90 first estimated assumed a T-3 start |
| Teardown | None |
| PRD | §2 Sequencing; §4; §5 |

## Outcome

The documented event matches the new plan, and the owner has decided what happens to C2's points.

```text
T-14  Event owner      Capture every subscription ID, index, object ID and email. Members run preflight
T-7   Platform lead    Pipeline run 1 (lead's repo): ALZ-lite. It creates id-sqlmi-directory.
                       A Privileged Role Administrator runs the Graph grant
T-3   Each member      C0 in their own repo (terminal or the member profile): preflight, datacenter,
                       Test-Datacenter, then Arc. Then the portal Arc assessment and vm-dev01 setup
T-1   Platform lead    Pipeline run 2 (lead's repo): vending for every member in order, VM restart,
                       exemptions, connectivity test. After the coach's C0 review and vm-dev01 setup
Day 1 Everyone         Start at C1. C2 verifies and explains the foundation
```

The hard dependencies are only these: ALZ-lite and each datacenter before vending, `Test-Datacenter` before Arc, and the Graph grant after ALZ-lite and before C7. The datacenter still exists before the subscription moves under the Corp group, so the exemptions lesson stays.

## Before you start

1. B18 is closed (issue #126), and B21 is at least designed.
2. Read `facilitator/guide.md`, `agenda.md`, `scoring-rubric.md`, `challenges/c00-…` and `c02-…`.

## Requirements

1. 🧑 HUMAN: the owner decides C2. Options: (a) keep 35 team points and re-base the evidence as "verify and explain" (coach questions on the policies, exemptions with owner and expiry, probes); (b) re-weight the points to other challenges. Record the decision in the PRD.
2. Update the timeline and gates in `facilitator/guide.md` and `agenda.md`: T-14 roster capture, T-7 foundation, T-3 C0, T-1 vending, and Day 1 without the 09:00 ALZ-lite start. Move the Privileged Role Administrator booking to T-7.
3. Rewrite the C2 page for the chosen option, and update C0's wording (nothing is removed from C0), `prerequisites.mdx`, `event-overview.md`, `roles.md`, `pre-work.md`, the glossary where needed, and the coach answer keys.
4. Re-anchor the Day 1 deny-policy curveball, which is scheduled during C2.
5. Update `scoring-rubric.md` and `scoreboard.md` for the owner's decision, and `cost-estimate.md` for the earlier foundation.
6. Update `facilitator/automation-map.md` and add the pipeline page (B20) to the coach section.
7. PRD §4 and §5, the roadmap and `versions.md` as needed.

## Deliverables

- The pages above, with every link and check passing.
- A short decision record in the PR body.

## Verify

- `npm run check` passes. No page still says the platform lead starts ALZ-lite at 09:00 on Day 1.
- The rubric totals still add up to 200 base points, or the new total is stated everywhere.

## Done when

- [ ] The owner approved the C2 decision.
- [ ] Guide, agenda, challenge pages, rubric and cost are consistent.

## Commit message

```text
docs: move ALZ-lite and vending before the event
```

## Stop and ask if

- A change would alter the points of a challenge without the owner's decision.

## Notes and traps

- Vending after `vm-dev01` setup is deliberate: vending changes the datacenter's DNS to the firewall, which is untested during VM setup.
- Don't remove the platform lead's manual path: the scripts stay the supported fallback.
