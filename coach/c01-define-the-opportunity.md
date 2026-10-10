# C1 answer key: Define the opportunity

> [!WARNING]
> Coach material. This page has the answers to C1. Attendees work it out as a team from the opportunity canvas template.

C1 is directional, not a technical challenge — your job is to confirm the team actually reasoned about all six dimensions, not that they picked the "correct" answer (there isn't one).

## Expected evidence

- `opportunity-canvas.md`, committed to the team repo, with all six dimensions (application, data, platform, security, operations, cost) filled in with specific content, not the template's placeholder comments left in place.
- A one-sentence target outcome every member can repeat without reading from the canvas.

## Model answer

A credible C1 canvas for Contoso University looks like:

- **Business case:** reduce the cost and risk of running Contoso University on aging infrastructure, while preparing it to run reliably in Azure.
- **Current pain:** .NET Framework 4.8 and IIS on a VM are a growing support and security burden; the SQL Server instance has no HA story; uploads and notifications have no cloud-native equivalent yet.
- **Target outcome:** Contoso University runs on .NET 10 and ASP.NET Core MVC, on App Service, against SQL Managed Instance, with Blob-backed uploads, Service Bus notifications, Key Vault secrets and Application Insights telemetry — provisioned through the CoE archetype.
- **Six dimensions**, one or two sentences each: Application (framework upgrade via the Upgrade agent), Data (online migration via MI link, no offline backup/restore), Platform (the CoE archetype's existing App Service/SQL MI/Blob/Service Bus shape, not a bespoke design), Security (managed identity everywhere, no secrets in app settings), Operations (OpenTelemetry to Application Insights replacing `Trace`/`Debug`), Cost (Azure Hybrid Benefit on, archetype resources sized for a lab, not production).

## Common mistakes

- Treating C1 as a checkbox exercise and leaving one-word answers per dimension ("Platform: Azure") — push for a sentence that states a direction, not just a category.
- Re-litigating the migration method or app framework choice here — that's C4's job, with ADRs. C1 should stay directional ("move to Azure, modernize the framework") without committing to specific tools yet.
- Skipping the "open questions" section when the team genuinely disagreed — a canvas with no open questions from a team that argued for ten minutes is a red flag, not a clean result.

## Partial credit

- Five of six dimensions covered well, one thin: partial credit, with a note to revisit the thin one before C4 needs it.
- Canvas filled in by one member alone, without the team actually discussing it: accept it, but flag it — C2 is a better moment to confirm the whole team is aligned, since it runs in parallel anyway.

## Reset

Not applicable — C1 produces a document, not infrastructure. Re-editing the canvas is enough.
