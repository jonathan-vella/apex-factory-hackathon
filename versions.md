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
