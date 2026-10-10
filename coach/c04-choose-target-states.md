# C4 answer key: Choose target states

> [!WARNING]
> Coach material. This page has the answers to C4. Attendees write their own ADRs and deferred-work register from C3's findings.

Four ADRs are the minimum bar: platform and migration method (team-level, `evidence/c04/adr-platform.md` and `adr-migration.md`), app and data (member-level, `evidence/c04/member-<n>/adr-app.md` and `adr-data.md`). The kit fixes the target states, so what you're checking is the alternative considered and the consequence, not the choice itself. Check each one actually states a decision, not just a restatement of the inputs.

## Expected evidence

- **Platform ADR (team):** decision = the CoE archetype's shape as-is (App Service, SQL MI, Blob, Service Bus, Key Vault, Application Insights); alternative considered = a bespoke platform design; consequence = the team inherits the archetype's existing sizing and policies rather than choosing their own.
- **Migration method ADR (team):** decision = Arc SQL migration assessment + MI link, online, planned cutover; alternative considered = offline backup/restore; consequence = near-zero downtime at the cost of needing a healthy, validated replica before cutover (C7).
- **App ADR (member):** decision = .NET 10 / ASP.NET Core MVC via the Upgrade agent; alternative considered = a rewrite from scratch; consequence = faster, lower-risk modernization, but inherits the app's existing design.
- **Data ADR (member):** decision = SQL Managed Instance, Microsoft Entra authentication only; alternative considered = SQL Server on an Azure VM; consequence = no SQL authentication path outside Development, simplifying secrets management.
- **Deferred-work register (team, `evidence/c04/deferred-work-register.md`):** every C3 finding not immediately fixed, each with an owner, a target and a timeline — one trace-flag removal entry per member must be present (owner = the member, target = "remove `-T1800 -T9567` from the source," timeline = "after C7 cutover"). The C2 exemptions should appear too.

## Common mistakes

- An ADR with no alternative considered — "we decided X" isn't a decision record without at least one road not taken and why.
- Re-litigating the platform ADR even though the shape is already fixed — the foundation is deployed in C2, and the archetype follows in C5; the ADR documents the platform decision, it doesn't re-open it.
- Deferred-work register entries with a vague timeline like "later" — require a specific trigger ("after cutover," "before C10 handover").
- Forgetting the trace-flag entry in the register because it was already triaged in C3 — triage in C3 isn't the same as tracking the removal step; both need to happen.

## Partial credit

- Platform and migration-method ADRs done well as a team, but app/data ADRs thin or missing for some members: partial credit per member, not blocking the team's score.
- Deferred-work register missing the trace-flag entry: partial credit, with a direct nudge to add it before moving to C5.

## Reset

Not applicable — C4 produces documents, not infrastructure.
