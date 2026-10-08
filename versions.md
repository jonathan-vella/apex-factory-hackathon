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
| .NET 10 SDK | `10.0.401` | `vm-dev01` (B04); B06 runs and clean-clone builds | 2026-09-24; 2026-10-02 (B06) |
| Bicep | CLI `0.47.16` | Datacenter Bicep build, `vm-dev01` (B04) | 2026-09-24 |
| SqlServer PowerShell module | `22.4.5.1`, latest from the PowerShell Gallery at run time (22.0 or later) | `db/perf-kit` workload and reset on `vm-dev01` (B05) | 2026-09-25 |
| VS Code | `1.139.0` | `vm-dev01`, B06 golden path host | 2026-09-25 (recorded in B06 run 1) |
| GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`, Upgrade agent) | `1.1.612` | B06 golden path (v3 rerun); installed at first logon on `vm-dev01` (B04 list, owner decision 2026-10-02). B06 requirement 11a used `1.1.596` (2026-09-28 to 2026-09-30) | 2026-10-02 |
| GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) | Not installed | Removed from `vm-dev01`'s install list (owner decision 2026-10-02). B06 run 1 used `1.24.26091501` (2026-09-25); the golden-path runs had `1.24.0` installed but disabled | 2026-10-02 |
| Golden-path models | Claude Opus 5.5 at Medium (assess and plan); Claude Sonnet 5.5 at Medium (execute) | B06 golden path, for B10 and B11 | 2026-10-02 |
| GitHub Copilot app `upgrade-agent` plugin | `1.1.612` (marketplace `upgrade-agent-plugins`) | B06 requirement 11b, paused; not part of the golden path. The app's own version wasn't recorded | 2026-10-01 |
| Copilot CLI | Not used | B06's optional Copilot CLI section wasn't tried | 2026-10-02 |
| Azure Connected Machine agent | `1.68.03532.3282`, latest from `https://aka.ms/AzureConnectedMachineAgent` at run time | `vm-app01` Arc onboarding, `scripts/Connect-DatacenterArc.ps1` (B07), swedencentral | 2026-10-02 |
| Azure extension for SQL Server (`WindowsAgent.SqlServer`) | `1.1.3547.472`, installed and upgraded automatically by Arc | Arc-enabled SQL Server and the MI link migration on `vm-app01` (B07) | 2026-10-02 |
| SQL MI database format (update policy) | `SQLServer2022` | MI link target, `docs/spikes/B07-arc-mi-link/infra/main.bicep` (B07); for B09 | 2026-10-02 |
| Azure Firewall and network APIs | `Microsoft.Network/azureFirewalls`, `firewallPolicies`, `firewallPolicies/ruleCollectionGroups`, `virtualNetworks`, `routeTables`, `networkSecurityGroups`, `publicIPAddresses` `2025-09-01`; `privateDnsZones` `2024-06-01` | `infra/foundation` (B08) | 2026-10-02 |
| Management group APIs | `Microsoft.Management/managementGroups` and `managementGroups/subscriptions` `2023-04-01` | `infra/foundation` (B08) | 2026-10-02 |
| Policy and RBAC APIs | `Microsoft.Authorization/policyAssignments` `2025-03-01`, `roleAssignments` `2022-04-01`; exemptions through `az policy exemption create` (Azure CLI 2.90.0) | `infra/foundation`, `scripts/New-DatacenterExemptions.ps1` (B08) | 2026-10-02 |
| Other foundation APIs | `Microsoft.OperationalInsights/workspaces` `2025-07-01`, `Microsoft.Security/pricings` `2024-01-01`, `Microsoft.Consumption/budgets` `2024-08-01`, `Microsoft.Insights/diagnosticSettings` `2021-05-01-preview`, `Microsoft.HybridCompute/machines/runCommands` `2025-01-13` | `infra/foundation`, `scripts/Test-Connectivity.ps1` (B08) | 2026-10-02 |
| APEX (`apex-factory-coe`, project `university`) | Commit `9a2019046992696a73e9f6b28cbaeac074d2413a` on `main` (re-emit: ACR `azureADAuthenticationAsArmPolicyStatus: 'enabled'`, SQL MI identity `SystemAssigned,UserAssigned` with primary `id-sqlmi-directory`), synced to upstream `apex-accelerator` `c209d8b`, tree hash `dcbe5478…` verified, ID scan 0 hits | `archetype/agent-output/university`, `archetype/infra/bicep/university` (B09) | 2026-10-07 |
| SQL MI database format (archetype) | `SQLServer2022`, `licenseType: 'BasePrice'` (AHB), Entra-only auth | `archetype/infra/bicep/university` MI (B09), validated live post-deploy | 2026-10-07 |
| AVM modules (archetype Bicep) | `resource-group:0.4.4`, `user-assigned-identity:0.6.0`, `insights/component:0.8.0`, `container-registry/registry:0.13.1`, `storage-account:0.33.1`, `service-bus/namespace:0.17.1`, `key-vault/vault:0.14.2`, `web/serverfarm:0.7.0`, `web/site:0.24.0`, `network/private-endpoint:0.12.1` | `archetype/infra/bicep/university` (B09) | 2026-10-07 |
