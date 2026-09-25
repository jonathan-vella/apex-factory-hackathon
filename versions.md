# Compatibility manifest

This manifest records the versions and source commit used by the kit. Tooling versions are pinned in the repository; marketplace images and vendor installers use the latest available version at deployment time.

| Component | Version | Used in | Validated |
|---|---|---|---|
| Node.js | 24.x | Root and site tooling (`.node-version`, `.nvmrc`) | 2026-09-24 (checks run with Node 26.7.0 by owner-approved deviation) |
| Astro | `^7.3.2` | `site/package.json` | 2026-09-24 |
| Starlight | `^0.42.1` | `site/package.json` | 2026-09-24 |
| APEX microhack tooling source | `f95c470` | Repository tooling and site scaffold | 2026-09-24 |
| PSScriptAnalyzer | 1.25.0 | `scripts/Test-Preflight.ps1` | 2026-09-24 |
| Contoso University (upstream sample) | `7c1bf47` | `app/ContosoUniversity` (B03) | 2026-09-24 |
| .NET Framework | `4.8` | Legacy app and its build (B03) | 2026-09-24 |
| System.Runtime.CompilerServices.Unsafe | `4.7.1` | `ContosoUniversity-legacy.zip` `bin` only, matching the app's `Web.config` redirect (B03) | 2026-09-24 |
| `vm-app01` image | `MicrosoftSQLServer:sql2022-ws2022:sqldev-gen2`, version `16.0.260610` | `infra/datacenter` (B04), swedencentral | 2026-09-24 |
| `vm-dev01` image | `MicrosoftWindowsDesktop:windows-11:win11-25h2-ent`, version `26200.9457.260913` | `infra/datacenter` (B04), swedencentral | 2026-09-24 |
| SQL Server 2022 Developer | `16.0.4255.1` (from the `vm-app01` image) | `vm-app01` (B04) | 2026-09-24 |
| VS Build Tools | `18.10.2`, current release, `Microsoft.VisualStudio.Workload.WebBuildTools` | `vm-dev01` (B04) | 2026-09-24 |
| SSMS | `22.10.1` | `vm-dev01` (B04) | 2026-09-24 |
| .NET 10 SDK | `10.0.401` | `vm-dev01` (B04) | 2026-09-24 |
| Bicep | CLI `0.47.16` | Datacenter Bicep build, `vm-dev01` (B04) | 2026-09-24 |
| SqlServer PowerShell module | `22.4.5.1`, latest from the PowerShell Gallery at run time (22.0 or later) | `db/perf-kit` workload and reset on `vm-dev01` (B05) | 2026-09-25 |
