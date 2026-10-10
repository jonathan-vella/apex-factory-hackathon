# AI-readiness gap register

<!--
Filled in during C10. Be honest: where did GitHub Copilot's agents need a human to unblock them, and what does that mean for running this unattended at a customer? If your team used coach support anywhere during the event, record it here as a gap, not as a failure.
-->

| Where | What needed a human | Why | Implication for AI readiness |
|---|---|---|---|
| <!-- example --> C2 | Deciding whether to exempt or fix a policy finding | The policy result doesn't say whether the exception is safe | Governance findings still need an expert decision, not blind automation |
| <!-- example --> C8 | Reading a failed acceptance check | A failing check says what failed, not whether it matters for this workload | Acceptance results still need a human sign-off before handover |

## Known platform gaps (carried over, not yours to fix)

- Defender for Cloud runs Foundational CSPM only in this kit's landing zone — a production AI-ready platform would also enable paid Defender plans for the workloads in scope.
