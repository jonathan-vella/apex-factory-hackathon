# C1 answer key: Define the opportunity

> [!WARNING]
> Coach material. This page has the answers to C1. Attendees work it out as a team from the opportunity canvas template.

C1 is directional, not a technical challenge. Your job is to confirm the team ranked the six business outcomes from the customer story, gave each a measure, and reasoned about all six dimensions. There is no correct order.

## Expected evidence

- `opportunity-canvas.md`, committed to `factory/evidence/c01/` in each member's own repo (score it once, from the team lead's copy; the other copies must match). It has the six outcomes ranked, each with a voice, a dimension, a measure and a target, and all six dimensions (application, data, platform, security, operations, cost) filled in with specific content, not the template's placeholder comments left in place.
- A one-sentence target outcome every member can repeat without reading from the canvas.

## Model answer

A credible C1 canvas for Contoso University looks like this. Another order is fine if the team can defend it.

| Rank | Outcome | Voice | Dimension | Measure | Target |
| --- | --- | --- | --- | --- | --- |
| 1 | Secure by default | Tomás | Security | No stored passwords or keys, no public data endpoints | Checked by the C8 acceptance pack |
| 2 | Current platform | Dana | Application | App runs on .NET 10 and ASP.NET Core on App Service | Seven agent task commits, image in the registry |
| 3 | Safe, repeatable change | Priya | Data | Planned cutover with a written rollback | Registrar's office stopped for under an hour (illustrative target) |
| 4 | Repeatable provisioning | Priya | Platform | Platform deployed from code with an As-Built record | `azd provision` succeeds from the repo |
| 5 | Reliable at enrollment peaks | Marcus | Operations | Slowest queries measured before and after tuning | Query Store numbers for all five fixes |
| 6 | Documented path to AI | Dana | Data | Gap register with owners | Every gap has an owner and a next step |

- **Why the top two are on top:** the audit raised security and the platform, so risk comes first, as in the customer story.
- **Why the last is last:** AI readiness depends on the data already being in a governed platform, so it follows the other five.
- **Target outcome:** Contoso University runs on .NET 10 and ASP.NET Core MVC, on App Service, against SQL Managed Instance, with Blob-backed uploads, Service Bus notifications, Key Vault secrets and Application Insights telemetry, provisioned through the CoE archetype.
- **Six dimensions**, one or two sentences each: Application (framework upgrade via the Upgrade agent), Data (online migration via MI link, no offline backup and restore), Platform (the CoE archetype's existing App Service, SQL MI, Blob and Service Bus shape, not a bespoke design), Security (managed identity everywhere, no secrets in app settings), Operations (OpenTelemetry to Application Insights replacing `Trace` and `Debug`), Cost (Azure Hybrid Benefit on, archetype resources sized for a lab, not production).

## Business outcome check

This challenge is the ranking itself. Check that the measure for the team's top-ranked outcome is something they could look at in the portal, a log or a test at the end of C10. This supports the canvas scoring row. It earns no points of its own.

## Common mistakes

- Treating C1 as a checkbox exercise: one-word answers per dimension ("Platform: Azure") or a measure nobody could check ("better security"). Push for a sentence that states a direction and a measure someone could look at.
- Ranking all six as equal. The ranking is the point: ask what the team gives up first if day two runs short.
- Re-litigating the migration method or app framework choice here — that's C4's job, with ADRs. C1 should stay directional ("move to Azure, modernize the framework") without committing to specific tools yet.
- Skipping the "open questions" section when the team genuinely disagreed — a canvas with no open questions from a team that argued for ten minutes is a red flag, not a clean result.

## Partial credit

- Five of six dimensions covered well, one thin: partial credit, with a note to revisit the thin one before C4 needs it.
- Canvas filled in by one member alone, without the team actually discussing it: accept it, but flag it — C2's walk-through is a better moment to confirm the whole team is aligned, since the whole team takes part in it.

## Reset

Not applicable — C1 produces a document, not infrastructure. Re-editing the canvas is enough.
