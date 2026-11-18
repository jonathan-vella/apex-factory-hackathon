# C4 answer key: Choose target states (coach)

> [!WARNING]
> Coach material. This page has the answers to C4. Attendees complete `factory/evidence/c04/decisions-and-register.md` in the team/pod lead's repository from C3's findings.

`factory/evidence/c04/decisions-and-register.md` (committed once in the team/pod lead's repo and shared in the team channel) combines the four target-state decisions (**Platform**, **Migration method**, **Application**, **Data**) and the **Deferred-work register** in one concise file. The kit fixes the target states, so what you're checking is the alternative considered, the reasoning tied to C1/C3, and the consequence/trade-off.

## Expected evidence

**Timing cues:** by 20 minutes, agree the target choices; reserve the last 15 minutes for the deferred-work register and committing on `main`. Ask for the missing rationale before suggesting a decision.

- **Platform row:** chosen target = CoE archetype in vended spoke (`App Service Linux P1v3`, `SQL MI GP Gen5 4 vCores`, private endpoints); alternative considered = bespoke Bicep from scratch or VM lift-and-shift; consequence = inherits the archetype's sizing and lab exceptions.
- **Migration method row:** chosen target = Arc SQL migration assessment + MI link (online seeding + planned cutover) and .NET SDK container publish to ACR; alternative considered = offline backup/restore and Dockerfile build; consequence = near-zero downtime and no Docker daemon needed on `vm-dev01`, at the cost of keeping trace flags `-T1800` and `-T9567` until cutover completes.
- **Application row:** chosen target = .NET 10 / ASP.NET Core MVC via the Upgrade agent with `DefaultAzureCredential`; alternative considered = keeping .NET Framework 4.8 on a VM or manual rewrite; consequence = faster, lower-risk modernization across 7 structured tasks.
- **Data row:** chosen target = SQL Managed Instance General Purpose (Gen5, 4 vCores, 64 GB, AHB `BasePrice`, Microsoft Entra authentication only); alternative considered = SQL Server on an Azure VM or Azure SQL Database; consequence = no SQL authentication path outside Development and post-cutover query tuning in C9.
- **Deferred-work register:** lists removing `-T1800` and `-T9567` on `vm-app01` after C7 cutover (`Prepare-MiLinkSource.ps1 -RemoveTraceFlags`), C9 Query Store tuning, and any other deferred C2/C3 items, each with a named owner, target resolution, and timeline.

## Business outcome check

The outcome is a current platform. Check that the decision rows tie back to the team's top-ranked outcome from C1 and that a reader outside the team could follow them.

## Common mistakes

- A row with no alternative considered — "we decided X" isn't a decision record without at least one road not taken and why.
- Deferred-work register entries with a vague timeline like "later" — require a specific trigger ("C7 Requirement 7," "C9," "Post-hackathon").
- Forgetting the trace-flag removal entry in the register because it was already triaged in C3.

## Reset

Not applicable — C4 produces a single Markdown document, not infrastructure.
