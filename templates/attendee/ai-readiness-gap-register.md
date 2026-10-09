# AI-readiness gap register

<!--
Filled in during C10. Be honest: where did GitHub Copilot's agents need a human to unblock them, and what does that mean for running this unattended at a customer? If your team used coach support anywhere during the event, record it here as a gap, not as a failure.
-->

| Where | What needed a human | Why | Implication for AI readiness |
|---|---|---|---|
| <!-- example --> C3 | Triage of the trace-flag finding | The assessment reports a warning without the context of why it's there | Assessment output still needs an expert read, not blind automation |
| <!-- example --> C7 | Go/no-go decision before cutover | Data-loss risk if a human doesn't confirm replication lag and source writes stopped | Migration cutover should stay a human-approved step, even in a mature pipeline |

## Known platform gaps (carried over, not yours to fix)

- Defender for Cloud runs Foundational CSPM only in this kit's landing zone — a production AI-ready platform would also enable paid Defender plans for the workloads in scope.
