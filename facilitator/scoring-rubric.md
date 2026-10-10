# Scoring rubric

This is the scoring single source of truth. The base contract is 80 team points and 120 member points: 200 total before bonuses. Challenge minutes and base points match the challenge pages.

## Scoring rules

- Lock the roster at kickoff. The member average includes every person on that roster; a missing or unverified item scores zero. Do not remove an absent member from the denominator after kickoff.
- Award team evidence once per team. Award member evidence separately for each member.
- Base team score = team base points + the arithmetic mean of member base points. The maximum base score is 200.
- Score each evidence row independently. Full points require the listed evidence. Award half the row value, rounded down, when evidence is present but one verifiable subcomponent is incomplete; award zero when evidence is absent, unverified or materially incorrect. Record the reason for partial credit. Never exceed a row's maximum or move unused points between rows.
- Lifelines cap the affected challenge only; later challenges remain eligible. Record the branch or image in the scoreboard. C6 use of L1, L2, L3, L4 or the known-good image caps C6 at **15 of 30 member points**. C7 use of L5 caps C7 at **10 of 20 member points**. Ordinary hints and coach discussion do not trigger a cap.
- Challenge bonus tasks and badges draw from one event-wide bonus pool capped at **30 points**. A badge is worth 5 team bonus points, once per team. Challenge bonus tasks are awarded to the scope of their challenge and retain the challenge-page maxima. When the pool is exhausted, further eligible bonus evidence is recorded but adds no points.
- Team score = team base points + average member base points + awarded team bonus + average awarded member bonus, with combined bonus capped at 30. The scoreboard shows the components separately.
- Coaches sign off evidence and the event owner resolves scoring disagreements against this rubric. Keep evidence in the team's repository; redact secrets and tenant, subscription and object IDs before sharing it publicly.

## Base points by challenge

| Challenge | Scope | Minutes | Team points | Member points |
|---|---|---:|---:|---:|
| C0 Ready to hack | Member | 150 | 0 | 10 |
| C1 Define the opportunity | Team | 45 | 10 | 0 |
| C2 Secure, AI-ready foundation | Team | 120 | 35 | 0 |
| C3 Assess the source | Member | 60 | 0 | 15 |
| C4 Choose target states | Team + member | 45 | 15 | 10 |
| C5 Deploy the CoE archetype with APEX | Member | 90 | 0 | 15 |
| C6 Modernize with GHCP | Member | 180 | 0 | 30 |
| C7 Migrate and go live | Member | 120 | 0 | 20 |
| C8 Validate the pattern | Member | 45 | 0 | 10 |
| C9 Optimize the DB with GHCP | Member | 60 | 0 | 10 |
| C10 Package, hand over, review AI readiness | Team | 60 | 20 | 0 |
| **Total** |  | **975** | **80** | **120** |

## Evidence points

### C0 — Ready to hack

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Preflight output is green and the member confirms the Azure Hybrid Benefit check | 0 | 2 |
| Datacenter test output is green, or a coach-approved failure is explained | 0 | 3 |
| `vm-app01` is Arc-connected and the SQL Server extension reports its instance | 0 | 3 |
| First Arc SQL migration assessment is captured | 0 | 2 |
| **Total** | **0** | **10** |

### C1 — Define the opportunity

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Committed opportunity canvas covers all six modernization dimensions | 6 | 0 |
| Team can state one clear target outcome together | 4 | 0 |
| **Total** | **10** | **0** |

### C2 — Secure, AI-ready foundation

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| ALZ-lite management groups, hub and policies are shown in deployment evidence | 10 | 0 |
| Vending output covers every member subscription and the expected network setup | 10 | 0 |
| Datacenter exemptions have an owner, reason and expiry | 5 | 0 |
| Connectivity probes pass every applicable check | 10 | 0 |
| **Total** | **35** | **0** |

### C3 — Assess the source

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Upgrade assessment is reviewed before task execution starts | 0 | 3 |
| Triage table covers findings, source, disposition and target-state impact | 0 | 5 |
| Trace-flag finding includes the reason, impact and removal decision | 0 | 5 |
| No application files have changed yet | 0 | 2 |
| **Total** | **0** | **15** |

### C4 — Choose target states

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Platform ADR states the decision, an alternative and a consequence | 5 | 0 |
| Migration-method ADR states the decision, an alternative and a consequence | 5 | 0 |
| Deferred-work register includes every deferred C3 finding and trace-flag removal | 5 | 0 |
| Member's app target-state ADR is complete | 0 | 5 |
| Member's data target-state ADR is complete | 0 | 5 |
| **Total** | **15** | **10** |

### C5 — Deploy the CoE archetype with APEX

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Adaptation output and successful `azd provision` deployment record | 0 | 5 |
| As-Built deployed-state document is present | 0 | 4 |
| Resource listing shows the expected archetype resources | 0 | 3 |
| Governance findings and their resolution are recorded | 0 | 3 |
| **Total** | **0** | **15** |

### C6 — Modernize with GHCP

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Seven task commits each have a passing build and local run | 0 | 8 |
| App runs on the dev VM against the source database; Blob upload, notification and telemetry checks pass | 0 | 8 |
| Vulnerability audit is clean or has documented remediation | 0 | 4 |
| Container image is present in the private registry | 0 | 5 |
| App Service identity, settings and Key Vault access are checked and recorded | 0 | 5 |
| **Total** | **0** | **30** |

### C7 — Migrate and go live

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Arc portal evidence shows the link seeded, replica validated, cutover completed and link removed | 0 | 5 |
| Live App Service pages show the migrated data | 0 | 5 |
| Contained user and supported `CREATE USER` statement are recorded | 0 | 5 |
| Source trace flags are removed and cutover/rollback runbook is committed | 0 | 5 |
| **Total** | **0** | **20** |

### C8 — Validate the pattern

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Acceptance and handover pack records each check and its evidence | 0 | 4 |
| Requests and dependencies from the validation session are visible in Application Insights | 0 | 3 |
| Every backend's public network access is confirmed off | 0 | 3 |
| **Total** | **0** | **10** |

### C9 — Optimize the DB with GHCP

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Query Store before/after evidence covers all five fixes | 0 | 4 |
| The five fix scripts are committed | 0 | 4 |
| Summary explains each change and measured impact | 0 | 2 |
| **Total** | **0** | **10** |

### C10 — Package, hand over, review AI readiness

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Reusable asset is committed and referenced by the handover | 6 | 0 |
| Acceptance and handover covers every team member | 5 | 0 |
| AI-readiness register has a credible entry for lifeline use or non-use | 5 | 0 |
| Factory-kit checklist is complete | 2 | 0 |
| Team showcase is delivered | 2 | 0 |
| **Total** | **20** | **0** |

## Badges

Each badge adds 5 team bonus points when its evidence is signed off. Badges share the event-wide 30-point bonus pool with challenge bonus tasks.

| Badge | Criteria | Evidence |
|---|---|---|
| Zero public backend endpoints | SQL MI, Blob, Service Bus, Key Vault and ACR are private-only; only the documented web front end and telemetry ingestion are public exceptions | C8 security check with the commands or portal views used |
| Policy clean | Kit Deny policies have no unapproved violations on the archetype resources; the documented datacenter exemptions are not counted as unapproved violations | Policy compliance evidence and the reviewed exemption register |
| Rollback ready | The team can explain the pre-cutover abort, the writable MI copy trap and the safe reseed plan | Committed cutover/rollback runbook, with C7 abort evidence if the curveball was triggered |
| Trust but verify | AI-produced changes are reviewed by a person and the relevant build, test or runtime checks are recorded | Task commits and check output linked from the team's evidence |
| Cost guardian | Team records the event cost, stops idle datacenter VMs outside the event days (never `vm-dev01` during the event) and accounts for the MI schedule and budget | Cost worksheet and shutdown/schedule evidence |
| Reusable-asset contributor | Another team could use the packaged asset without undocumented tribal knowledge | C10 asset, README and handover reference |

## Challenge bonus tasks

Use the bonus opportunities on the challenge pages: C2, C3, C5, C6, C7 and C8 offer up to 5 points each; C10 offers up to 10. C0, C1, C4 and C9 have no bonus task. Award only documented evidence and apply the shared 30-point ceiling.
