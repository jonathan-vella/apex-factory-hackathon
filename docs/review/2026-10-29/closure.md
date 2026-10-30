# B24 closure audit

**Audited:** 30 October 2026. **Implementation baseline:** `0708734ce90478057696268031537deccfbb8148`.

| Severity | Closed | Deferred | Open | Total |
|---|---:|---:|---:|---:|
| P0 | 2 | 0 | 0 | 2 |
| P1 | 22 | 1 | 1 | 24 |
| P2 | 86 | 0 | 0 | 86 |
| P3 | 163 | 3 | 2 | 168 |
| **All** | **273** | **4** | **3** | **280** |

## Scope and evidence

This audit adds only this document. It makes no fixes, changes no Azure resources and does not claim a new application, portal or migration rehearsal.

The dated findings register remains the original review record. Each row below points to its current page; the theme heading links the merged implementation and its finding disposition. Closed means the permitted fix or overriding decision is implemented, not that every future event prerequisite has happened. Deferred means a required part is explicitly on the spec's Deferred list. Open means an acceptance check or another requested part remains incomplete.

Partial findings are counted once at the less-complete status. START-01 is Deferred even though its incorrect C2 values are fixed. CRF-37 is Closed by the bounded coach-overview fix in #213; CHA-04 remains Open because static recovery checks are not the requested fresh-terminal Azure rehearsal.

The owner authorized local theme execution and merging passing PRs. All ten implementation PRs are merged, and #213 merged the bounded CRF-37 fix. Issue #195 is closed; #196 remains open for the CHA-04 rehearsal; #198 remains open for CHB-22 and DEP-26 portal verification. Issues #190 through #194, #197 and #199 are closed. PRs #184 and #185 were also merged after their dependency validations passed. PR #212 carries this closure record for review.

## Verification

| Check | Result and boundary |
|---|---|
| `npm run check` | Passed: content invariants, six Node tests, Markdown lint and formatting. Ten challenges, 750 minutes, 170 base points: 45 team and 125 member. |
| `npm --prefix site run build` | Passed. Existing non-fatal bundle-size and empty i18n-collection warnings remain. |
| `npm --prefix site run lint:prose` | Vale was not installed in this worktree. The GitHub Validate Docs check passed on #213 with the merged lockfiles. |
| `node scripts/check-internal-links.mjs` | Passed: 85 HTML files, including fragment checks. |
| Search for `alzl-deny-public-acr` in `site/src`, `coach`, `facilitator` | No hits. Historical review records intentionally retain original evidence. |
| Search for absolute `https://factory.apexops.pro` links in `coach`, `facilitator` | No hits. |
| Search for `(tell\|ask) your coach` or `a coach can help` in attendee content | All 19 hits reviewed: About feedback, event-day challenges, C5/Arc event recovery, and event troubleshooting. No pre-event escalation depends on a coach. |
| Last Prompts page pager | Copilot app goes to Reference, not Coach. |
| Step 4, C10, Tear down and About pagers | Step 4 goes to Challenges; C10 goes to Tear down; Tear down and About have no Next. |
| JourneyMap | Rendered C2 says Member, 45 min, 15 pts. The ten rendered rows sum to 750 minutes and 170 points; this is a computed check, not a claim the page prints a separate total. |
| Coach scoring | Coach overview renders C2 bonus as `up to 5 pts`. |
| Coach sidebar and titles | Coach is last. The overview's Run the event list now matches the sidebar's order and exact labels for all eight non-challenge pages. Local rendered output and the live overview were checked; URLs are unchanged, and all eight linked coach pages returned HTTP 200. All 19 child coach-page H1s end in `(coach)`; the landing page is distinctly titled Coach cheat sheets. |
| T10 presentation | One homepage H1 with `_top`; five shared figures on the C7, ALZ-lite and naming/IP routes; old `day-one` and `day-two` anchors retained. |
| T10 CI | Validate Docs, PowerShell, Bicep and workflow checks passed on #211. Initial PowerShell failure was a stale C7 `.md` test path; corrected to `.mdx`, with 35 local MI-source checks passing. Test assertions and runtime logic unchanged. |
| Public URL preservation | Three source-extension renames retained their routes. Registered finding pages exist in built output, with `/404` represented by `404.html`; existing legacy redirects remain. |
| Code scope | T01 guard and teardown conditions are the planned behavior change. The owner additionally approved the homepage-only default-title condition in #211 and the bounded coach-overview data/label change in #213. Other code edits are documentation, strings, data/sidebar configuration or the renamed test fixture path. No application or Bicep logic change. |
| Mirrored templates | `npm run check` enforces equality; all attendee and team template copies match. |

### CI-lab acceptance evidence

These were explicitly owner-approved CI-lab runs, not operations against the owner's live lab:

- [Missing-members guard](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/40880535446): expected plan-job refusal.
- [Filtered member teardown](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/40908820894): member removed and team teardown skipped.
- [Full lifecycle teardown](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/40912814521): completed after foundation, member deployment and vending, linked in #201.
- [Deferred push-path test](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/41013408710): completed after later owner approval; idempotent teardown against the already-removed lab, not a second fresh lifecycle.

Issue #190 records that temporary identities, federation, scoped grants, resource groups, pipeline settings and the test branch were removed; the pre-existing CI sandbox and subscription placement were preserved.

No additional Azure work was performed for #196 or #198. The ignored `.local/ci-lab.json` and `.local/settings.json` files were absent from this worktree, so the intended test targets could not be verified against the owner live lab. No Azure call or portal operation was attempted.

### Publication

[Manual GitHub Pages deployment](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/41021626736) succeeded at the audited implementation commit. The live homepage, glossary, C6/C7, ALZ-lite, naming/IP, coach scoreboard, teardown and C8 pages were checked for HTTP 200 and their changed content. Publication is not a new runtime validation of the Azure lab.

[Automatic GitHub Pages deployment after #213](https://github.com/jonathan-vella/apex-factory-hackathon/actions/runs/41027437767) succeeded. The live Coach overview and all eight linked coach pages returned HTTP 200; the overview contains every expected link and label in sidebar order.

## Finding dispositions

Page links below are the current rendered evidence surface, not the historical quote in the register. Read the corresponding finding's Fix together with the spec's overriding decision; the original register is not rewritten.

### T01: implementation [#201](https://github.com/jonathan-vella/apex-factory-hackathon/pull/201)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CRF-01 | P0 | Closed | [/reference/troubleshooting/][page-60] |  |
| DEP-01 | P0 | Closed | [/deploy/member-steps/][page-30] |  |
| CRF-07 | P1 | Closed | [/coach/readiness/][page-26] |  |
| CRF-09 | P1 | Closed | [/reference/azure-hybrid-benefit/][page-56] |  |
| DEP-02 | P1 | Closed | [/deploy/member-steps/][page-30] |  |
| DEP-03 | P1 | Closed | [/deploy/vending/][page-34] |  |
| CRF-13 | P2 | Closed | [/coach/readiness/][page-26] |  |
| CRF-27 | P2 | Closed | [/reference/azure-hybrid-benefit/][page-56] |  |
| DEP-07 | P2 | Closed | [/deploy/member-steps/][page-30] |  |
| START-07 | P2 | Closed | [/getting-started/event-overview/][page-36] |  |
| DEP-20 | P3 | Closed | [/coach/readiness/][page-26] |  |

### T02: implementation [#202](https://github.com/jonathan-vella/apex-factory-hackathon/pull/202)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CRF-08 | P1 | Closed | [/reference/troubleshooting/][page-60] |  |
| DEP-04 | P1 | Closed | [/getting-started/requirements/][page-38] |  |
| START-02 | P1 | Closed | [/getting-started/requirements/][page-38] |  |
| START-05 | P1 | Closed | [/getting-started/roles/][page-39] |  |
| CRF-14 | P2 | Closed | [/coach/c05/][page-19] |  |
| DEP-16 | P2 | Closed | [/deploy/][page-28] |  |
| DEP-19 | P2 | Closed | [/reference/troubleshooting/][page-60] |  |
| GDE-09 | P2 | Closed | [/guides/alz-lite/][page-41] | Decision 9 overrides register suggestion: lead books PRA; event owner escalates. |
| GDE-10 | P2 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| START-15 | P2 | Closed | [/getting-started/roles/][page-39] |  |
| CHA-33 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| DEP-29 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| START-35 | P3 | Closed | [/getting-started/requirements/][page-38] |  |
| START-38 | P3 | Closed | [/getting-started/requirements/][page-38] |  |

### T03: implementation [#204](https://github.com/jonathan-vella/apex-factory-hackathon/pull/204)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| DEP-05 | P1 | Closed | [/getting-started/requirements/][page-38] | Decision 3: preserve owner observation and document plan limitations; no universal Free-plan claim. |
| START-03 | P1 | Closed | [/getting-started/requirements/][page-38] | Decision 4: CLI optional; required seats, models and policies documented. |
| START-04 | P1 | Closed | [/getting-started/requirements/][page-38] |  |
| CRF-11 | P2 | Closed | [/coach/readiness/][page-26] |  |
| CRF-24 | P2 | Closed | [/reference/cost/][page-57] | Price estimate explicitly remains checked 2026-10-08, not repriced. |
| CRF-25 | P2 | Closed | [/reference/cost/][page-57] |  |
| CRF-26 | P2 | Closed | [/reference/azure-hybrid-benefit/][page-56] |  |
| DEP-09 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| DEP-10 | P2 | Closed | [/deploy/team-lead-steps/][page-32] |  |
| START-09 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| START-10 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| START-11 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| START-12 | P2 | Closed | [/getting-started/requirements/][page-38] | Decision 10: Docker licensing note, no replacement toolchain. |
| START-13 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| START-14 | P2 | Closed | [/getting-started/requirements/][page-38] |  |
| CRF-40 | P3 | Closed | [/reference/cost/][page-57] |  |
| DEP-31 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-34 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-35 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| START-17 | P3 | Closed | [/getting-started/requirements/][page-38] |  |
| START-37 | P3 | Closed | [/about/][page-03] |  |

### T04: implementation [#205](https://github.com/jonathan-vella/apex-factory-hackathon/pull/205)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| START-01 | P1 | Deferred | [/getting-started/kit-at-a-glance/][page-37] | C2 data corrected and rendered totals checked; automated component/data guard remains deferred. |
| CHA-05 | P2 | Closed | [/challenges/c01-define-the-opportunity/][page-05] |  |
| CHA-14 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHB-06 | P2 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| GDE-03 | P2 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| GDE-04 | P2 | Closed | [/prompts/][page-46] |  |
| GDE-13 | P2 | Closed | [/guides/apex/][page-42] | Decision 7: 07b works but is unsupported at events; azd retained. |
| CHA-23 | P3 | Closed | [/challenges/][page-04] |  |
| CHA-37 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHB-18 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-21 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-25 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] | Playbook Step 5 is canonical; duplicate skill instructions replaced by a link, documentation only. |
| CHB-40 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CHB-43 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] | Decision 12: team lead owns scored curveball evidence. |
| DEP-22 | P3 | Closed | [/deploy/how-it-works/][page-29] |  |
| DEP-30 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-33 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-43 | P3 | Closed | [/getting-started/roles/][page-39] |  |
| DEP-44 | P3 | Closed | [/deploy/][page-28] |  |
| GDE-27 | P3 | Closed | [/guides/apex/][page-42] |  |
| START-20 | P3 | Closed | [/about/][page-03] |  |
| START-23 | P3 | Closed | [/getting-started/kit-at-a-glance/][page-37] |  |
| START-26 | P3 | Closed | [/getting-started/kit-at-a-glance/][page-37] |  |
| START-36 | P3 | Closed | [/][page-01] |  |

### T05: implementation [#206](https://github.com/jonathan-vella/apex-factory-hackathon/pull/206)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| LEAD-01 | P1 | Closed | [/prompts/copilot-app/][page-47] |  |
| CRF-30 | P2 | Closed | [/reference/cost/][page-57] |  |
| DEP-08 | P2 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-17 | P2 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| GDE-06 | P2 | Closed | [/prompts/vscode/07-triage-assessment-findings/][page-54] |  |
| GDE-07 | P2 | Closed | [/guides/alz-lite/][page-41] |  |
| GDE-11 | P2 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| LEAD-02 | P2 | Closed | [/deploy/vending/][page-34] |  |
| START-06 | P2 | Closed | [/getting-started/][page-35] |  |
| START-16 | P2 | Closed | [/getting-started/][page-35] |  |
| CHA-22 | P3 | Closed | [/challenges/][page-04] |  |
| CHA-24 | P3 | Closed | [/challenges/][page-04] |  |
| CHA-32 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-35 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHA-36 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHA-39 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHB-11 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-20 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-23 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-24 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-42 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CHB-45 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| DEP-36 | P3 | Closed | [/deploy/][page-28] |  |
| DEP-39 | P3 | Closed | [/deploy/vending/][page-34] |  |
| GDE-25 | P3 | Closed | [/guides/arc-mi-link/][page-43] |  |
| GDE-26 | P3 | Closed | [/guides/apex/][page-42] |  |
| GDE-31 | P3 | Closed | [/guides/][page-40] |  |
| GDE-32 | P3 | Closed | [/guides/][page-40] |  |
| GDE-33 | P3 | Closed | [/prompts/vscode/07-triage-assessment-findings/][page-54] |  |
| GDE-41 | P3 | Closed | [/prompts/vscode/00-prerequisites/][page-48] |  |
| GDE-42 | P3 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| GDE-43 | P3 | Closed | [/prompts/][page-46] |  |
| GDE-44 | P3 | Closed | [/guides/apex/][page-42] |  |
| LEAD-03 | P3 | Closed | [/prompts/copilot-app/][page-47] |  |
| LEAD-09 | P3 | Closed | [/coach/lifelines/][page-25] | Decision 15: (coach) labels, not search exclusion. |
| START-19 | P3 | Closed | [/about/][page-03] |  |
| START-30 | P3 | Closed | [/getting-started/][page-35] |  |
| START-33 | P3 | Closed | [/][page-01] |  |

### T06: implementation [#207](https://github.com/jonathan-vella/apex-factory-hackathon/pull/207)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CRF-03 | P1 | Closed | [/coach/c02/][page-18] |  |
| CRF-04 | P1 | Closed | [/coach/run-of-show/][page-27] |  |
| CRF-05 | P1 | Closed | [/coach/][page-15] |  |
| CRF-06 | P1 | Closed | [/coach/c06/][page-20] |  |
| CRF-10 | P2 | Closed | [/coach/c02/][page-18] | Bonus rendered correctly through content workaround; loader regex still deferred. |
| CRF-12 | P2 | Closed | [/coach/readiness/][page-26] | Audience expressed outside stripped alert; loader alert handling still deferred. |
| CRF-15 | P2 | Closed | [/coach/deploy-with-scripts/][page-24] |  |
| CRF-16 | P2 | Closed | [/coach/deploy-with-scripts/][page-24] |  |
| CRF-17 | P2 | Closed | [/coach/lifelines/][page-25] |  |
| CRF-18 | P2 | Closed | [/coach/][page-15] |  |
| CRF-19 | P2 | Closed | [/coach/readiness/][page-26] |  |
| CRF-20 | P2 | Closed | [/coach/][page-15] |  |
| CRF-22 | P2 | Closed | [/coach/run-of-show/][page-27] | Decision 6: full-ALZ segment scheduled in kickoff; owner still supplies slides/recording. |
| CRF-31 | P2 | Closed | [/coach/c09/][page-22] |  |
| GDE-14 | P2 | Closed | [/guides/alz-lite/][page-41] | Decision 6: kickoff replaces claim of a C2 live demo; owner media still outstanding. |
| CHA-34 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHA-47 | P3 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHB-35 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CHB-39 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CRF-32 | P3 | Closed | [/coach/c05/][page-19] |  |
| CRF-33 | P3 | Closed | [/coach/lifelines/][page-25] |  |
| CRF-34 | P3 | Closed | [/coach/lifelines/][page-25] |  |
| CRF-35 | P3 | Closed | [/coach/c07/][page-21] |  |
| CRF-36 | P3 | Closed | [/coach/run-of-show/][page-27] |  |
| CRF-37 | P3 | Closed | [/coach/][page-15] | #213 aligns the Run the event links and labels with the Coach sidebar, including all eight non-challenge pages; existing URLs are unchanged. Local render and live pages verified. |
| CRF-38 | P3 | Deferred | [/coach/][page-15] | Shared description and disabled lastUpdated remain; per-page metadata is explicitly deferred. |
| CRF-44 | P3 | Closed | [/coach/deploy-with-scripts/][page-24] |  |
| CRF-45 | P3 | Deferred | [/coach/automation-map/][page-16] | Relative links fixed; extending Vale to coach/facilitator remains deferred. |
| CRF-46 | P3 | Closed | [/coach/automation-map/][page-16] |  |
| CRF-47 | P3 | Closed | [/coach/c02/][page-18] |  |
| CRF-48 | P3 | Deferred | [/coach/c01/][page-17] | Coach-sheet previous/next component work remains explicitly deferred. |
| LEAD-04 | P3 | Closed | [/coach/readiness/][page-26] |  |
| LEAD-07 | P3 | Closed | [/coach/][page-15] |  |
| START-18 | P3 | Closed | [/getting-started/event-overview/][page-36] | Agenda moved into Event overview; runtime generation remains deferred. |
| START-29 | P3 | Closed | [/getting-started/roles/][page-39] |  |

### T07: implementation [#208](https://github.com/jonathan-vella/apex-factory-hackathon/pull/208)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CHA-01 | P1 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-02 | P1 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] | Decision 2: none needed is valid; do not manufacture exemptions. |
| CHA-03 | P1 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHA-04 | P1 | Open | [/challenges/c05-deploy-the-coe-archetype/][page-09] | Explicit preflight parameters and mirrored recovery docs fixed; fresh-terminal Azure rehearsal not performed. |
| CRF-02 | P1 | Closed | [/coach/c02/][page-18] |  |
| GDE-01 | P1 | Closed | [/prompts/vscode/07-triage-assessment-findings/][page-54] |  |
| CHA-06 | P2 | Closed | [/challenges/c01-define-the-opportunity/][page-05] |  |
| CHA-08 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-09 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-10 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-11 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-12 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-13 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-15 | P2 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-17 | P2 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHA-18 | P2 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHA-19 | P2 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHA-20 | P2 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHB-01 | P2 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-02 | P2 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-03 | P2 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] | Decision 11: post-cutover rollback documented, not exercised. |
| CHB-04 | P2 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-07 | P2 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] | Decision 14: both template copies updated identically. |
| CHB-08 | P2 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CRF-23 | P2 | Closed | [/coach/c10/][page-23] |  |
| CRF-28 | P2 | Closed | [/reference/troubleshooting/][page-60] |  |
| DEP-11 | P2 | Closed | [/deploy/vending/][page-34] |  |
| DEP-12 | P2 | Closed | [/deploy/member-steps/][page-30] |  |
| DEP-18 | P2 | Closed | [/deploy/team-lead-steps/][page-32] |  |
| GDE-05 | P2 | Closed | [/prompts/vscode/03-cve-scan/][page-50] |  |
| GDE-12 | P2 | Closed | [/guides/apex/][page-42] |  |
| CHA-26 | P3 | Closed | [/challenges/c01-define-the-opportunity/][page-05] |  |
| CHA-27 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-28 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-29 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-30 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-40 | P3 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHA-43 | P3 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHA-45 | P3 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHA-46 | P3 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHA-48 | P3 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHA-49 | P3 | Closed | [/challenges/c05-deploy-the-coe-archetype/][page-09] |  |
| CHB-12 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-15 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-16 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-17 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-19 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] |  |
| CHB-26 | P3 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-27 | P3 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-29 | P3 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-32 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CHB-34 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CHB-36 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CHB-37 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CHB-38 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CHB-41 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| CHB-44 | P3 | Closed | [/challenges/c10-package-hand-over-review-ai-readiness/][page-14] |  |
| DEP-21 | P3 | Closed | [/deploy/how-it-works/][page-29] |  |
| DEP-23 | P3 | Closed | [/deploy/member-steps/][page-30] |  |
| DEP-24 | P3 | Closed | [/deploy/member-steps/][page-30] |  |
| DEP-27 | P3 | Closed | [/deploy/team-lead-steps/][page-32] |  |
| DEP-28 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-38 | P3 | Closed | [/deploy/vending/][page-34] |  |
| DEP-42 | P3 | Closed | [/deploy/vending/][page-34] |  |
| GDE-21 | P3 | Closed | [/guides/alz-lite/][page-41] |  |
| GDE-22 | P3 | Closed | [/guides/alz-lite/][page-41] |  |
| GDE-40 | P3 | Closed | [/prompts/][page-46] |  |
| START-28 | P3 | Closed | [/getting-started/roles/][page-39] |  |

### T08: implementation [#209](https://github.com/jonathan-vella/apex-factory-hackathon/pull/209)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| DEP-06 | P1 | Closed | [/deploy/tear-down/][page-33] |  |
| CRF-21 | P2 | Closed | [/coach/automation-map/][page-16] |  |
| DEP-13 | P2 | Closed | [/deploy/tear-down/][page-33] | Decision 8: deletion is the documented T+2 default; workflow boolean default unchanged. |
| DEP-14 | P2 | Closed | [/deploy/tear-down/][page-33] |  |
| DEP-15 | P2 | Closed | [/deploy/tear-down/][page-33] |  |
| START-08 | P2 | Closed | [/getting-started/event-overview/][page-36] |  |
| CRF-43 | P3 | Closed | [/reference/troubleshooting/][page-60] |  |
| DEP-40 | P3 | Closed | [/deploy/tear-down/][page-33] |  |
| DEP-41 | P3 | Closed | [/deploy/tear-down/][page-33] |  |

### T09: implementation [#210](https://github.com/jonathan-vella/apex-factory-hackathon/pull/210)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CHA-07 | P2 | Closed | [/challenges/c01-define-the-opportunity/][page-05] |  |
| CHA-16 | P2 | Closed | [/challenges/c03-assess-the-source/][page-07] | Decision 5: recorded baseline and file evidence; future current-version retest is owner work. |
| CHB-05 | P2 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| GDE-02 | P2 | Closed | [/prompts/vscode/01-assess-and-plan/][page-49] | Decision 5: baseline/fallback delivered, not a new runtime test. |
| GDE-08 | P2 | Closed | [/guides/learning-path/][page-45] |  |
| GDE-15 | P2 | Closed | [/prompts/copilot-app/][page-47] |  |
| GDE-16 | P2 | Closed | [/guides/learning-path/][page-45] |  |
| CHA-31 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] |  |
| CHA-38 | P3 | Closed | [/challenges/c03-assess-the-source/][page-07] |  |
| CHA-42 | P3 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHB-13 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] | Decision 13: retain Azure Monitor distro with new-app guidance; migration deferred. |
| CHB-14 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] | Decision 5: baseline/fallback delivered; owner retests before the dry run. |
| CHB-22 | P3 | Open | [/challenges/c07-migrate-and-go-live/][page-11] | Honest source-check date added; actual C7 portal verification remains open in #198. |
| CHB-31 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CRF-39 | P3 | Closed | [/reference/availability-zones/][page-55] |  |
| DEP-25 | P3 | Closed | [/deploy/member-steps/][page-30] |  |
| DEP-26 | P3 | Open | [/deploy/member-steps/][page-30] | Current Learn path documented; actual Arc portal assessment verification remains open in #198. |
| GDE-17 | P3 | Closed | [/guides/learning-path/][page-45] |  |
| GDE-18 | P3 | Closed | [/guides/learning-path/][page-45] |  |
| GDE-19 | P3 | Closed | [/guides/learning-path/][page-45] |  |
| GDE-20 | P3 | Closed | [/guides/learning-path/][page-45] |  |
| GDE-23 | P3 | Closed | [/guides/alz-lite/][page-41] |  |
| GDE-24 | P3 | Closed | [/guides/arc-mi-link/][page-43] |  |
| GDE-30 | P3 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| GDE-38 | P3 | Closed | [/prompts/copilot-app/][page-47] |  |
| LEAD-05 | P3 | Closed | [/challenges/c02-secure-ai-ready-foundation/][page-06] | T09 primary-source checks and canonical links; not a claim every external site is perpetually available. |
| START-34 | P3 | Closed | [/getting-started/requirements/][page-38] |  |

### T10: implementation [#211](https://github.com/jonathan-vella/apex-factory-hackathon/pull/211)

| Finding | Severity | Status | Evidence page | Qualification |
|---|---|---|---|---|
| CRF-29 | P2 | Closed | [/reference/glossary/][page-58] |  |
| CHA-21 | P3 | Closed | [/challenges/][page-04] |  |
| CHA-25 | P3 | Closed | [/challenges/c01-define-the-opportunity/][page-05] |  |
| CHA-41 | P3 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHA-44 | P3 | Closed | [/challenges/c04-choose-target-states/][page-08] |  |
| CHB-09 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-10 | P3 | Closed | [/challenges/c06-modernize-with-ghcp/][page-10] |  |
| CHB-28 | P3 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-30 | P3 | Closed | [/challenges/c08-validate-the-pattern/][page-12] |  |
| CHB-33 | P3 | Closed | [/challenges/c09-optimize-the-db-with-ghcp/][page-13] |  |
| CRF-41 | P3 | Closed | [/reference/glossary/][page-58] |  |
| CRF-42 | P3 | Closed | [/reference/naming-and-ip-plan/][page-59] |  |
| DEP-32 | P3 | Closed | [/deploy/set-up-your-repo/][page-31] |  |
| DEP-37 | P3 | Closed | [/deploy/][page-28] |  |
| GDE-28 | P3 | Closed | [/guides/apex/][page-42] |  |
| GDE-29 | P3 | Closed | [/guides/ghcp-upgrade/][page-44] |  |
| GDE-34 | P3 | Closed | [/prompts/vscode/00-prerequisites/][page-48] |  |
| GDE-35 | P3 | Closed | [/prompts/vscode/04-troubleshoot/][page-51] |  |
| GDE-36 | P3 | Closed | [/prompts/vscode/05-app-service-check/][page-52] |  |
| GDE-37 | P3 | Closed | [/prompts/vscode/06-acceptance-pack/][page-53] |  |
| GDE-39 | P3 | Closed | [/prompts/][page-46] |  |
| LEAD-06 | P3 | Closed | [/404][page-02] |  |
| LEAD-08 | P3 | Closed | [/challenges/c07-migrate-and-go-live/][page-11] | Three MDX source renames preserve URLs; five shared Diagram figures verified. |
| START-21 | P3 | Closed | [/getting-started/event-overview/][page-36] |  |
| START-22 | P3 | Closed | [/getting-started/event-overview/][page-36] |  |
| START-24 | P3 | Closed | [/getting-started/kit-at-a-glance/][page-37] |  |
| START-25 | P3 | Closed | [/getting-started/kit-at-a-glance/][page-37] |  |
| START-27 | P3 | Closed | [/getting-started/roles/][page-39] |  |
| START-31 | P3 | Closed | [/][page-01] | Owner-approved homepage-only condition; one H1 and original _top verified. |
| START-32 | P3 | Closed | [/about/][page-03] |  |
| START-39 | P3 | Closed | [/getting-started/requirements/][page-38] |  |
| START-40 | P3 | Closed | [/getting-started/kit-at-a-glance/][page-37] |  |
| START-41 | P3 | Closed | [/getting-started/roles/][page-39] |  |

## Explicit deferred code work

The spec also defers code improvements whose immediate findings were resolved through content or a decision. Their presence here does not reopen a fixed documentation defect:

| Work | Disposition |
|---|---|
| Check JourneyMap/components against `challenges.json` | START-01 Deferred; data fixed, automatic cross-source guard absent. |
| Extend Vale to coach/facilitator | CRF-45 Deferred; relative links fixed. |
| Coach-sheet previous/next | CRF-48 Deferred. |
| Individual coach meta descriptions/dates | CRF-38 Deferred. |
| Coach loader bonus regex and alert stripping | CRF-10/CRF-12 Closed through documented content workarounds; loader changes still deferred. |
| Generate Event overview agenda from facilitator source | START-18 Closed by moving the attendee tables; runtime generation still deferred. |
| Exclude coach pages from search | LEAD-09 Closed by decision 15's explicit title-label alternative. |
| One template copy instead of two | Deferred reviewer note without its own finding ID; both copies currently match. |
| Move to Microsoft OpenTelemetry distro | CHB-13 Closed under decision 13; migration remains deferred. |

## Open items and owner prerequisites

| Item | Remaining action |
|---|---|
| CHA-04, T07, #196 | Rehearse the documented C5/APEX preflight recovery in a fresh terminal in an approved disposable lab. Blocked this turn because the ignored CI-lab and live settings files were absent from the worktree, so the safe target could not be verified; no Azure call was attempted. |
| CHB-22 and DEP-26, T09, #198 | Verify the current C7 migration and Arc assessment portal UI before the event; record actual versions/labels and validation dates. Blocked for the same missing local configuration; no Azure or portal operation was attempted. Source-check dates are not live-test dates. |
| Decision 5 prerequisite | The Upgrade-toolchain retest is intentionally deferred until next week. The owner updates `versions.md` with actual results before the dry run; recorded baseline and fallback documentation are already delivered. |
| Decision 6 prerequisite | Owner supplies two or three full-ALZ kickoff slides or a short recording. Schedule and coaching documentation are delivered; media was not generated or falsely claimed present. |

No further Azure deployment or deletion is authorized by this audit. Deferred code work needs a separate scope decision, not an unreviewed fix in this document-only PR.

[page-01]: https://factory.apexops.pro/
[page-02]: https://factory.apexops.pro/404
[page-03]: https://factory.apexops.pro/about/
[page-04]: https://factory.apexops.pro/challenges/
[page-05]: https://factory.apexops.pro/challenges/c01-define-the-opportunity/
[page-06]: https://factory.apexops.pro/challenges/c02-secure-ai-ready-foundation/
[page-07]: https://factory.apexops.pro/challenges/c03-assess-the-source/
[page-08]: https://factory.apexops.pro/challenges/c04-choose-target-states/
[page-09]: https://factory.apexops.pro/challenges/c05-deploy-the-coe-archetype/
[page-10]: https://factory.apexops.pro/challenges/c06-modernize-with-ghcp/
[page-11]: https://factory.apexops.pro/challenges/c07-migrate-and-go-live/
[page-12]: https://factory.apexops.pro/challenges/c08-validate-the-pattern/
[page-13]: https://factory.apexops.pro/challenges/c09-optimize-the-db-with-ghcp/
[page-14]: https://factory.apexops.pro/challenges/c10-package-hand-over-review-ai-readiness/
[page-15]: https://factory.apexops.pro/coach/
[page-16]: https://factory.apexops.pro/coach/automation-map/
[page-17]: https://factory.apexops.pro/coach/c01/
[page-18]: https://factory.apexops.pro/coach/c02/
[page-19]: https://factory.apexops.pro/coach/c05/
[page-20]: https://factory.apexops.pro/coach/c06/
[page-21]: https://factory.apexops.pro/coach/c07/
[page-22]: https://factory.apexops.pro/coach/c09/
[page-23]: https://factory.apexops.pro/coach/c10/
[page-24]: https://factory.apexops.pro/coach/deploy-with-scripts/
[page-25]: https://factory.apexops.pro/coach/lifelines/
[page-26]: https://factory.apexops.pro/coach/readiness/
[page-27]: https://factory.apexops.pro/coach/run-of-show/
[page-28]: https://factory.apexops.pro/deploy/
[page-29]: https://factory.apexops.pro/deploy/how-it-works/
[page-30]: https://factory.apexops.pro/deploy/member-steps/
[page-31]: https://factory.apexops.pro/deploy/set-up-your-repo/
[page-32]: https://factory.apexops.pro/deploy/team-lead-steps/
[page-33]: https://factory.apexops.pro/deploy/tear-down/
[page-34]: https://factory.apexops.pro/deploy/vending/
[page-35]: https://factory.apexops.pro/getting-started/
[page-36]: https://factory.apexops.pro/getting-started/event-overview/
[page-37]: https://factory.apexops.pro/getting-started/kit-at-a-glance/
[page-38]: https://factory.apexops.pro/getting-started/requirements/
[page-39]: https://factory.apexops.pro/getting-started/roles/
[page-40]: https://factory.apexops.pro/guides/
[page-41]: https://factory.apexops.pro/guides/alz-lite/
[page-42]: https://factory.apexops.pro/guides/apex/
[page-43]: https://factory.apexops.pro/guides/arc-mi-link/
[page-44]: https://factory.apexops.pro/guides/ghcp-upgrade/
[page-45]: https://factory.apexops.pro/guides/learning-path/
[page-46]: https://factory.apexops.pro/prompts/
[page-47]: https://factory.apexops.pro/prompts/copilot-app/
[page-48]: https://factory.apexops.pro/prompts/vscode/00-prerequisites/
[page-49]: https://factory.apexops.pro/prompts/vscode/01-assess-and-plan/
[page-50]: https://factory.apexops.pro/prompts/vscode/03-cve-scan/
[page-51]: https://factory.apexops.pro/prompts/vscode/04-troubleshoot/
[page-52]: https://factory.apexops.pro/prompts/vscode/05-app-service-check/
[page-53]: https://factory.apexops.pro/prompts/vscode/06-acceptance-pack/
[page-54]: https://factory.apexops.pro/prompts/vscode/07-triage-assessment-findings/
[page-55]: https://factory.apexops.pro/reference/availability-zones/
[page-56]: https://factory.apexops.pro/reference/azure-hybrid-benefit/
[page-57]: https://factory.apexops.pro/reference/cost/
[page-58]: https://factory.apexops.pro/reference/glossary/
[page-59]: https://factory.apexops.pro/reference/naming-and-ip-plan/
[page-60]: https://factory.apexops.pro/reference/troubleshooting/
