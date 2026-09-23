# B13: Dry run, tune and release v1.0

| Field | Value |
|---|---|
| Milestone | P5 Pilot and v1.0 |
| Type | Both |
| Depends on | B12 |
| Unblocks | — |
| Effort | 1 week elapsed, including a 2-day dry run |
| Cost | Dry-run tenant: one team's shared services subscription plus a member stack per participant, for about 5 days (T-3 to cleanup). Use `facilitator/cost-estimate.md`, and confirm with the partner before T-3 |
| Teardown | Everything, with `scripts/Remove-FactoryEnvironment.ps1`, after the dry run |
| PRD | §1 Success metrics; §5; §7 Deliverables 5 |

## Outcome

- One team of partner-like attendees runs the whole event in a dry-run tenant, with a coach who isn't the author.
- Time boxes, points and content are tuned from what happened, `versions.md` is validated, and v1.0 is tagged and released.

## Before you start

1. B12 is closed.
2. 🧑 HUMAN: the owner confirms the dry run: dates, a team of 3–5 partner engineers, a coach, a dry-run tenant with one shared services subscription and a workload subscription per participant, Owner at the tenant root management group for the platform lead, and Copilot seats.

## Requirements

### Run it

1. 🧑 HUMAN: participants complete the pre-work by T-3 (preflight GO at T-14 or as early as possible, datacenter deployed, Arc onboarded, `scripts/Test-Datacenter.ps1` passing).
2. 🧑 HUMAN: the team runs Day 1 and Day 2 following the site, the coach following `facilitator/`. The coach fills in the scoreboard, triggers both curveballs and hands out lifelines as needed.
3. Collect during the event: actual time per challenge per participant, blockers and how they were solved, lifelines used, questions coaches had to answer that the content should have, and the Copilot models and premium requests used.
4. Collect after the event: a short survey of participants and the coach, with the questions in `docs/spikes/B13-dry-run/survey.md`, which you write before the event.

### Measure

5. Compare against the PRD success metrics: at least 90% of members green at T-3, at least 80% reaching cutover, lifeline use per challenge, and whether the coach ran it without the author.

### Tune

6. Change time boxes, points, hints, the agenda and troubleshooting pages from the evidence. Keep the 200 base points and the content-check contract in sync. Record each change and its reason in the report.
7. Re-validate each row in `versions.md` that the dry run exercised, with the date.

### Clean up

8. Run `scripts/Remove-FactoryEnvironment.ps1` for every member and the team. Confirm nothing billable from the kit is left. Fix the script if it missed anything.

### Release

9. `docs/spikes/B13-dry-run/README.md` follows the spike report format, with the metrics, timings, changes and follow-ups.
10. Update the root `README.md` status to v1.0 and the PRD status to released.
11. The PR body carries this after-merge checklist for the owner: 🧑 HUMAN: tag `v1.0.0` on `main` and create a GitHub release with notes (what the kit contains, the validated versions and region, known limitations). Write the release notes in `docs/spikes/B13-dry-run/release-notes.md` so the owner can paste them.

## Deliverables

- `docs/spikes/B13-dry-run/README.md`, `survey.md` and `release-notes.md`.
- Tuned content in `site/`, `facilitator/`, `coach/` and `scripts/check-content-invariants.mjs`.
- `versions.md`, `README.md` and `docs/prd.md` updated.

## Verify

```powershell
npm run check
Push-Location site; npm run build; Pop-Location
```

- Checks pass. After the merge, the owner checks `gh release view v1.0.0`.

## Done when

- [ ] The dry run happened, and the report compares it with the success metrics.
- [ ] Tuning changes are made and recorded.
- [ ] Cleanup left nothing billable.
- [ ] The release notes and the after-merge checklist are in the PR.

## Commit message

```text
docs: tune the kit from the dry run and release v1.0
```

## Stop and ask if

- The success metrics are missed by a wide margin: the owner decides whether to release or run another dry run.
- A tuning change needs a PRD decision to change.

## Notes and traps

- **Don't coach from the author's head:** if the coach needs the author to unblock something, that's a content gap. Record it and fix the content.
- **Scrub the report:** participants and the tenant belong to a partner.
