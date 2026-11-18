# Target-state decisions and deferred-work register (C4)

<!--
Committed once in the team/pod lead's repository (`factory/evidence/c04/decisions-and-register.md`) and shared in the team channel.
-->

## Target-state decisions

| Area | Chosen target & SKU / configuration | Alternative considered | Why chosen (grounded in C1 outcomes & C3 findings) | Consequences / trade-offs |
| --- | --- | --- | --- | --- |
| **Platform** | CoE archetype in vended spoke (`App Service Linux P1v3`, `SQL MI GP Gen5 4 vCores`, private endpoints) | Custom Bicep from scratch or VM lift-and-shift | Reuses pre-approved landing zone guardrails and cuts provisioning time | Accepts archetype defaults (Key Vault purge protection off in lab, public web front end) |
| **Migration method** | Managed Instance link (online seeding + planned cutover) and .NET SDK container publish to ACR | Offline `.bacpac` export/import; Dockerfile build | Near-zero cutover downtime for 2M-row database; no Docker daemon needed on `vm-dev01` | Requires startup trace flags `-T1800` and `-T9567` on source until cutover completes |
| **Application** | .NET 10 ASP.NET Core MVC with `DefaultAzureCredential` (Blob Storage, Service Bus, Key Vault, OpenTelemetry) | Keep .NET Framework 4.8 on Windows Containers | Removes `System.Web`, local disk state, MSMQ, and connection-string secrets | Requires 7 structured upgrade tasks and gap verification in C6 |
| **Data** | Azure SQL Managed Instance General Purpose (Gen5, 4 vCores, 64 GB, AHB `BasePrice`, Entra auth) | Azure SQL Database single DB or SQL Server on Azure VMs | Instance-level compatibility with Managed Instance link and cross-feature parity | Query regressions after cutover are tuned in C9 with Query Store |

## Deferred-work register

| Finding or item | Source | Owner | Target resolution | Timeline |
| --- | --- | --- | --- | --- |
| Remove startup trace flags `-T1800` and `-T9567` on `vm-app01` | C3 | | Run `Prepare-MiLinkSource.ps1 -RemoveTraceFlags` after MI link deletion | C7 Requirement 7 |
| Tune top resource-consuming queries on SQL MI | C3 / C4 | | Apply index and SARGable query fixes using Query Store | C9 |
| Enable paid Microsoft Defender for Cloud workload plans | C2 / C4 | | Upgrade from Foundational CSPM in production landing zone | Post-hackathon |
