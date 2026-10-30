# Scoring rubric

This is the single source of truth for base points and evidence. Scoring rules, lifeline caps, badges and challenge bonus tasks live in [Scoreboard and badges](../coach/scoreboard.md). The base contract is 45 team points and 125 member points: 170 total before bonuses. Challenge minutes and base points match the challenge pages. The pre-hackathon setup has no points: it is checked automatically by `vending` and described on the [Readiness check page](../coach/readiness.md).

## Base points by challenge

| Challenge | Scope | Minutes | Team points | Member points |
|---|---|---:|---:|---:|
| C1 Define the opportunity | Team | 45 | 10 | 0 |
| C2 Secure, AI-ready foundation | Member | 45 | 0 | 15 |
| C3 Assess the source | Member | 60 | 0 | 15 |
| C4 Choose target states | Team + member | 45 | 15 | 10 |
| C5 Deploy the CoE archetype with APEX | Member | 90 | 0 | 15 |
| C6 Modernize with GHCP | Member | 180 | 0 | 30 |
| C7 Migrate and go live | Member | 120 | 0 | 20 |
| C8 Validate the pattern | Member | 45 | 0 | 10 |
| C9 Optimize the DB with GHCP | Member | 60 | 0 | 10 |
| C10 Package, hand over, review AI readiness | Team | 60 | 20 | 0 |
| **Total** |  | **750** | **45** | **125** |

## Evidence points

### C1 — Define the opportunity

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Committed opportunity canvas ranks the six business outcomes, maps each to a problem/trigger, CAF category, stakeholder voice, solution, KPI and target, and covers all six modernization dimensions | 6 | 0 |
| Team can state one clear target outcome statement linking trigger, solution and measurable outcome together | 4 | 0 |
| **Total** | **10** | **0** |

### C2 — Secure, AI-ready foundation

Each member runs C2 in their own dev container and vended `rg-spoke` to test an AI coding agent against two guardrail layers (APEX repository baseline and Azure Landing Zone `Deny` policies), plus datacenter exemptions and connectivity.

| Evidence item | Team pts | Member pts |
|---|---:|---:|
| Layer 1 (`guardrail-test.md`): AI agent prompt/response against `iac-security-baseline.md`, failing `validate:iac-security-baseline` output on `registry.bicep`, and clean `git restore` | 0 | 5 |
| Layer 2 (`guardrail-test.md`): `RequestDisallowedByPolicy` errors in `rg-spoke` for `alzl-deny-public-acr` and `alzl-deny-nic-pip`, with `pip-guardrail-test` cleaned up | 0 | 5 |
| Exemptions, connectivity and takeaway (`guardrail-test.md`): `rg-datacenter` exemptions table, `Test-Connectivity.ps1` `PASS` output, and two-sentence explanation of why ALZ guardrails are mandatory for agentic AI | 0 | 5 |
| **Total** | **0** | **15** |

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
| AI-readiness register records each time a coach unblocked the team, including a supplied checkpoint, or credible non-use with the human reviews still needed | 5 | 0 |
| Factory-kit checklist is complete | 2 | 0 |
| Team showcase is delivered | 2 | 0 |
| **Total** | **20** | **0** |
