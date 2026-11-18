# Assessment triage (C3)

<!--
Review the database assessment in Azure Arc and the application assessment in `.github/upgrades/` on `vm-dev01`.
Classify each finding as `must-fix` (blocks migration/modernization), `defer` (valid follow-up for C4's deferred register), or `ignore` (false positive or out of scope), with a brief reason.
-->

| Source (DB or App) | Finding | Disposition (`must-fix` / `defer` / `ignore`) | Reason and where it is handled |
| --- | --- | --- | --- |
| DB (Arc assessment) | Trace flags `-T1800` and `-T9567` enabled on `vm-app01` | `defer` | Required while Managed Instance link seeding is active; remove after C7 cutover (`Prepare-MiLinkSource.ps1 -RemoveTraceFlags`) |
| App (`.github/upgrades/`) | `System.Web` / ASP.NET MVC 5 startup (`Global.asax.cs`, `App_Start/`) | `must-fix` | Replaced by ASP.NET Core `Program.cs` and `wwwroot/` in C6 |
| App (`.github/upgrades/`) | Local file uploads (`~/Uploads/TeachingMaterials`) | `must-fix` | Moved to Azure Blob Storage (`teaching-materials`) via managed identity in C6 |
| App (`.github/upgrades/`) | MSMQ notifications (`.\private$\contosouniversity-notifications`) | `must-fix` | Moved to Azure Service Bus (`notifications` queue) via managed identity in C6 |
| App (`.github/upgrades/`) | `System.Diagnostics.Trace` / `Debug` logging | `must-fix` | Replaced by `ILogger<T>` and Azure Monitor OpenTelemetry in C6 |
