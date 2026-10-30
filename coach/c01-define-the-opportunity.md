# C1 answer key: Define the opportunity (coach)

> [!WARNING]
> Coach material. This page has the answers to C1. Attendees work it out as a team from the opportunity canvas template.

C1 is directional, not a deployment challenge. Attendees work as Solution Architects applying the Cloud Adoption Framework (CAF) Strategy methodology: connecting each customer problem and trigger to a prioritized business outcome, a CAF category, the solution component in this factory, and a measurable KPI verified later in C8, C9 or C10. There is no single right ranking order if the team can defend its reasoning.

## Expected evidence

**Timing cues:** by 20 minutes, the six outcomes are ranked; reserve the final 10 minutes for the target statement and evidence commit. Offer a question, not an answer, if the team is still debating scope.

- `opportunity-canvas.md`, committed to `factory/evidence/c01/` in each member's own repo (score it once, from the team lead's copy; the other copies must match). It has the six outcomes ranked, each mapped to a problem/trigger, a CAF outcome category, a stakeholder voice, a solution, a KPI and a target, and all six dimensions (application, data, platform, security, operations, cost) filled in with specific content and no template placeholder comments left in place.
- A one-sentence target outcome statement linking the customer trigger, the modernized solution and the measurable business outcome that every member can repeat without reading from the canvas.

## Model answer

A credible C1 canvas for Contoso University looks like this. Another order is fine if the team can defend it.

| Rank | Problem / Trigger | Outcome (CAF category) | Voice | Solution | KPI | Target |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | SQL password in `Web.config`, open network paths, missing logs | Secure by default (Reduce business risk) | Tomás | Managed identity, Key Vault, private endpoints, ALZ policies | C8 endpoint checker; C6/C7 configuration checks for secrets | 0 public data endpoints; separately 0 stored passwords/keys |
| 2 | Hand-patched .NET Framework VM, no container pipeline | Current platform (Enhance agility and efficiency) | Dana | .NET 10 container on App Service for Linux | Task commits and live container (C6/C7) | All 7 tasks complete; container running |
| 3 | Fragile releases and cutover downtime | Safe, repeatable change (Reduce business risk) | Priya and Marcus | Online MI link, planned cutover and recovery runbook | Duration and row-count checks (C7) | Under 60 minutes (illustrative); 100% row match |
| 4 | Manual builds and configuration drift | Repeatable provisioning (Enhance agility and efficiency) | Priya | Bicep archetype through `azd`, As-Built documentation | Provision status and deployment log (C5) | Clean provision; no manual portal fixes |
| 5 | Enrollment stalls at registration peaks | Reliable at enrollment peaks (Reduce business risk) | Marcus | SQL MI and Query Store tuning | Before/after duration and CPU (C9) | Measured reduction across all 5 workloads |
| 6 | AI roadmap needed; data siloed and ungoverned | Documented path to AI (Accelerate innovation) | Dana | Governed SQL MI/Blob data and gap register | Completed AI-readiness register (C10) | Every gap has a named owner and next action |

- **Why the top two are on top:** the internal audit flagged plaintext credentials and an aging platform on a single VM, so security risk and platform currency come first.
- **Why the last is last:** AI readiness depends on the data already living in a governed cloud platform, so it follows the other five outcomes.
- **Target outcome:** To resolve Contoso University's audit and reliability triggers, we will modernize the enrollment app onto `.NET 10` on Azure App Service for Linux and Azure SQL Managed Instance through the CoE archetype, verified by zero stored secrets, zero public data endpoints and measurable Query Store gains before handover.
- **Six dimensions**, one or two sentences each: Application (framework upgrade via the Upgrade agent to `.NET 10` and ASP.NET Core MVC), Data (online migration via SQL MI link, no offline backup and restore), Platform (the CoE archetype's existing App Service, SQL MI, Blob and Service Bus shape deployed with `azd provision`), Security (managed identity everywhere, no secrets in app settings, ALZ `Deny` policies active), Operations (OpenTelemetry to Application Insights replacing `Trace` and `Debug`), Cost (Azure Hybrid Benefit applied, archetype resources sized within the member subscription budget).

## Business outcome check

This challenge sets the outcome and KPI chain for the rest of the event. Check that the KPI for the team's top-ranked outcome is something they can verify in the portal, a log or a test in C8, C9 or C10. This supports the canvas scoring row and earns no separate points.

## Common mistakes

- Treating C1 as a checkbox exercise: one-word answers per dimension ("Platform: Azure") or a vague KPI nobody could measure ("better security"). Push for a problem/trigger, a solution component and a KPI someone can inspect in C8, C9 or C10.
- Ranking all six as equal. The ranking is the point: ask what the team gives up first if day two runs short.
- Re-litigating the migration method or app framework choice here. That belongs in C4's ADRs. C1 connects problems to business outcomes, solutions and KPIs.
- Skipping the **Open questions** section when the team disagreed. A canvas with no open questions from a team that debated for ten minutes is a sign they did not record the trade-off for C4.

## Partial credit

- Five of six dimensions covered well, one thin: partial credit, with a note to revisit the thin one before C4 needs it.
- Canvas filled in by one member alone, without the team discussing it: accept it, but check during C4 that the whole team can explain the ranking and target outcome.

## Reset

Not applicable. C1 produces a document, not infrastructure. Re-editing the canvas is enough.
