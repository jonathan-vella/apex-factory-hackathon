---
title: "C1: Define the opportunity"
description: The team scopes the modernization opportunity and a six-dimension plan.
---

## Goal

Agree, as a team, what "modernized" means for Contoso University and write it down before any infrastructure exists.

## Scope and time box

Team. **45 min** (runs in parallel with ALZ-lite deploying in C2 — don't wait for it).

## Points

**10 pts** (team).

## Inputs

None beyond the kit brief: Contoso University, an ASP.NET MVC 5 app on .NET Framework 4.8, moving to .NET 10 and Azure.

## Your tasks

1. Fill in the [opportunity canvas](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/opportunity-canvas.md) as a team: the business case, the current pain, and the target outcome in plain language.
2. Cover the six modernization dimensions in the canvas: application, data, platform, security, operations and cost. For each, write one or two sentences on where Contoso University is today and where you intend to take it.
3. Agree on what "done" looks like for the team by the end of day two, in terms a sponsor would accept as a handover.
4. Commit the filled-in canvas to your team repo.

## Evidence

- `opportunity-canvas.md`, committed, with all six dimensions filled in (not left as the template's placeholder text).
- A one-sentence target outcome the whole team can repeat.

## Hints

<details>
<summary>We don't agree on scope</summary>

Time-box the disagreement: write both views in the canvas's "open questions" area and move on. C4's ADRs are where you commit to specific choices; C1 is directional.
</details>

<details>
<summary>We're not sure what counts as a "dimension"</summary>

Application: code and framework. Data: storage and schema. Platform: compute and networking. Security: identity and secrets. Operations: telemetry and support. Cost: what you'll spend and how you'll justify it. One line each is enough for C1.
</details>

## Lifeline

A content lifeline is available if your team is stuck on the canvas format itself (not on the business decision) — ask your coach. Point cap: using it caps C1 at partial credit.

## Bonus

None for C1.

## Learn more

- [Cloud Adoption Framework: strategy and plan](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/)
- [App Service migration planning guidance](https://learn.microsoft.com/azure/app-service/migrate-overview)
