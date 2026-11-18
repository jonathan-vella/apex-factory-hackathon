# B25: Single-clone `vm-dev01` workstation bootstrap and pre-existing VM migration

## Goal

Enable students in next week's already-provisioned delivery (and all future deliveries) to run 100% of `C1`–`C10` on `vm-dev01` in a single clone (`C:\src\<repo-name>` on `main`), with a one-command bootstrap script (`scripts/Initialize-Workstation.ps1`) that:

1. Upgrades pre-existing `vm-dev01` VMs by installing Node.js 24 LTS (`node`) and Azure Developer CLI (`azd`) if missing.
2. Authenticates `gh`, `az`, and `azd` and sets `AZURE_TOKEN_CREDENTIALS=AzureCliCredential`.
3. Auto-detects `MemberIndex`, `SubscriptionId`, `TenantId`, `Location`, and `SharedSubscriptionId` from `vm-dev01`'s private IP (`10.10.<n>.5` or `10.<128..191>.<0..255>.5`) and the hub VNet peering so students type zero GUIDs.
4. Creates the student's private GitHub repository (`<github-user>/apex-factory-m<nn>` by default, or `<GitHubOwner>/<RepoName>`) from `jonathan-vella/apex-accelerator`, runs `Import-Kit.ps1` to populate `factory/`, `factory/evidence/`, `app/ContosoUniversity`, `.github/modernization/`, `.github/skills/`, `.github/instructions/contoso-university.instructions.md`, and `infra/bicep/university/` on `main`, writes `.local/settings.json` + `.local/<subId>/datacenter.json`, and opens VS Code.
5. Keeps `infra/datacenter/scripts/Test-DevVm.ps1` backwards-compatible with already-deployed VMs so `Test-Datacenter.ps1` never fails before a student logs in.
6. Validates `Import-Kit.ps1`, `Initialize-Workstation.ps1`, and `Prepare-MiLinkSource.ps1 -RemoveTraceFlags` offline in CI (`test/Test-WorkstationAndImport.Tests.ps1`).

---

## Phase 1: `scripts/Initialize-Workstation.ps1`

Create `scripts/Initialize-Workstation.ps1` (`#Requires -Version 7.4`, `[CmdletBinding(SupportsShouldProcess)]`, `$ErrorActionPreference = 'Stop'`, clean under `PSScriptAnalyzer`):

### Parameters

- `[string] $GitHubOwner = ''`: Optional GitHub organization or user. Defaults to the signed-in `gh` user login.
- `[string] $RepoName = ''`: Optional repository name. Defaults to `apex-factory-m<nn>` (where `<nn>` is `$MemberIndex.ToString('D2')`).
- `[string] $TemplateRepository = 'jonathan-vella/apex-accelerator'`: Template repository used by `gh repo create --template`.
- `[string] $KitRepository = 'jonathan-vella/apex-factory-hackathon'`: Kit repository passed to `Import-Kit.ps1`.
- `[string] $Ref = 'main'`: Git ref passed to `Import-Kit.ps1`.
- `[string] $TenantId = ''`: Optional override for Microsoft Entra tenant ID.
- `[string] $SubscriptionId = ''`: Optional override for workload subscription ID.
- `[string] $SharedSubscriptionId = ''`: Optional override for shared services subscription ID.
- `[int] $MemberIndex = 0`: Optional override for member index `n` (`1` or greater).
- `[string] $Location = ''`: Optional override for Azure region.
- `[string] $Suffix = ''`: Optional override for the 6-character archetype suffix.
- `[string] $WorkspaceRoot = ''`: Parent directory where the student repository is cloned. Defaults to `'C:\src'` on Windows or `(Join-Path $HOME 'src')` on Linux/macOS.
- `[switch] $SkipToolInstall`: Skips checking/installing `node` and `azd` (used in offline unit tests or when pre-verified).
- `[switch] $SkipOpenCode`: Skips launching `code` at the end of setup.

### Step 1: In-place tool upgrade for pre-existing `vm-dev01` VMs

- Refresh `$env:Path` from `[Environment]::GetEnvironmentVariable('Path', 'Machine')` and `'User'` (on Windows).
- Check `Get-Command node -ErrorAction SilentlyContinue` and `Get-Command azd -ErrorAction SilentlyContinue`.
- If either is missing and `-not $SkipToolInstall`:
  - On Windows, verify elevation (`[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()` in role `Administrator`). If not elevated, re-invoke the installer helper via `Start-Process pwsh -Verb RunAs -Wait` (or throw a clear message if UAC is declined).
  - Download and install **Node.js 24 LTS** (`https://nodejs.org/dist/index.json` -> `node-v24.x.x-x64.msi` via `msiexec.exe /i ... /qn /norestart`) and add `C:\Program Files\nodejs` to Machine `Path`.
  - Download and install **Azure Developer CLI (`azd`)** (`https://aka.ms/azd-windows-amd64.msi` via `msiexec.exe /i ... /qn /norestart ALLUSERS=1`) and add `C:\Program Files\Azure Dev CLI` to Machine `Path`.
  - Refresh `$env:Path` in the current process so `node` and `azd` are immediately available without restarting the terminal.

### Step 2: Sign in to GitHub, Azure CLI, and `azd`

- **GitHub CLI (`gh`):**
  - Run `gh auth status`. If exit code is non-zero, run `gh auth login --hostname github.com --git-protocol https --scopes repo,workflow --web`.
  - If already signed in, ensure the `workflow` OAuth scope is granted (since `Import-Kit.ps1` adds `.github/workflows/platform.yml`); if missing, run `gh auth refresh --hostname github.com --scopes repo,workflow`.
  - Run `gh auth setup-git`.
  - Query `gh api user` (`login`, `name`, `id`). Configure global git author to `user.name = $(if ($u.name) { $u.name } else { $u.login })` and `user.email = "$($u.id)+$($u.login)@users.noreply.github.com"`.
  - If `-not $GitHubOwner`, set `$GitHubOwner = $u.login`.
- **Azure CLI (`az`) & `azd`:**
  - Run `az account show`. If exit code is non-zero, run `az login --use-device-code` (adding `--tenant $TenantId` when `$TenantId` is provided).
  - Run `azd auth login --check-status`. If exit code is non-zero, run `azd auth login --use-device-code`.
- **Entra token credential variable:**
  - Set `[Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')` (on Windows) and `$env:AZURE_TOKEN_CREDENTIALS = 'AzureCliCredential'`.

### Step 3: Auto-detect `MemberIndex`, `SubscriptionId`, `TenantId`, `Location`, and `SharedSubscriptionId`

- **Auto-detect `MemberIndex` (when `$MemberIndex -le 0`):**
  - Read IPv4 addresses via a cross-platform helper `Get-LocalIPv4Addresses` (using `Get-NetIPAddress -AddressFamily IPv4` when available, or `[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()` on Linux/Cloud Shell).
  - Match `^10\.10\.([1-9]\d*)\.5$` -> `$MemberIndex = [int]$Matches[1]`.
  - Or match `^10\.(12[89]|1[3-8]\d|19[01])\.(\d+)\.5$` -> `$MemberIndex = (([int]$Matches[1] - 127) * 256) + [int]$Matches[2]`.
  - If neither matches, throw a clear error asking the caller to pass `-MemberIndex`.
- **Compute expected `vnet-datacenter` address prefix:**
  - `$block = [int][Math]::Floor($MemberIndex / 256)`
  - `$dcOct2 = if ($block -eq 0) { 10 } else { 127 + $block }`
  - `$oct3 = $MemberIndex % 256`
  - `$expectedDcPrefix = "10.$dcOct2.$oct3.0/24"`
- **Auto-detect and verify `SubscriptionId`, `TenantId`, and `Location`:**
  - If `-not $SubscriptionId`, list enabled subscriptions (`az account list --query "[?state=='Enabled'].{id:id, tenantId:tenantId, name:name}" -o json`) and probe `az network vnet show -g rg-datacenter -n vnet-datacenter --subscription <id> --query "addressSpace.addressPrefixes" -o json` across every candidate subscription (even when only 1 subscription is returned).
  - Fail closed if `0` subscriptions match `$expectedDcPrefix` or if more than `1` subscription matches `$expectedDcPrefix` (instructing the user to pass `-SubscriptionId` explicitly).
  - Run `az account set --subscription $SubscriptionId`.
  - Read `$TenantId` from the matched subscription if not supplied.
  - Read `$Location` from `az group show -n rg-datacenter --subscription $SubscriptionId --query location -o tsv` (falling back to `'swedencentral'`) if not supplied.
- **Auto-detect `SharedSubscriptionId` (when `-not $SharedSubscriptionId`):**
  - Query peerings on `rg-datacenter/vnet-datacenter` (and fallback to `rg-spoke/vnet-spoke`):
    `az network vnet peering list -g rg-datacenter --vnet-name vnet-datacenter --subscription $SubscriptionId --query "[].remoteVirtualNetwork.id" -o tsv`
  - Match `/subscriptions/([0-9a-fA-F-]{36})/resourceGroups/rg-hub/` and extract `$SharedSubscriptionId = $Matches[1]`.
- Mask all GUIDs in console output using `Protect-SensitiveText` (`$text -replace $guidRegex, '<id>'`), including piping output from child scripts (`Initialize-Settings.ps1`) through `Protect-SensitiveText`.

### Step 4: Create or clone the student's single private repository and run `Import-Kit.ps1`

- Default `$RepoName` to `"apex-factory-m$('{0:D2}' -f $MemberIndex)"` when empty.
- `$fullRepo = "$GitHubOwner/$RepoName"` and `$repoPath = Join-Path $WorkspaceRoot $RepoName`.
- Check if `repos/$fullRepo` exists via `gh api "repos/$fullRepo"`:
  - If not found (404), create it from `$TemplateRepository`:
    `gh repo create $fullRepo --private --template $TemplateRepository`
    and poll `repos/$fullRepo/commits?per_page=1` (up to 12 attempts, 2 seconds apart) until the initial template commit is ready.
  - If found and `$existingRepo.private -ne $true`, throw a fail-closed error refusing to use a public repository.
- If `Test-Path (Join-Path $repoPath '.git')` is false, clone `https://github.com/$fullRepo.git` to `$repoPath`.
- If `$repoPath` already exists:
  - Verify `git -C $repoPath remote get-url origin` matches `$fullRepo` (fail closed if it points to a different repository).
  - Verify `git -C $repoPath status --porcelain` is clean before running the import (if dirty, refuse to overwrite or stage unrelated work).
  - Run `git -C $repoPath switch main` and `git -C $repoPath pull --rebase origin main`.
- Locate `Import-Kit.ps1` (if `C:\src\factory` exists, run `git -C C:\src\factory fetch origin $Ref` and `git -C C:\src\factory checkout $Ref` first, or download `Import-Kit.ps1` from `https://raw.githubusercontent.com/$KitRepository/$Ref/scripts/Import-Kit.ps1`) and run:
  `& $importKitScript -Destination $repoPath -KitRepository $KitRepository -Ref $Ref -Force`
- Stage changes in `$repoPath` (`git -C $repoPath add -A`). If `git -C $repoPath status --porcelain` is non-empty, commit with `$env:LEFTHOOK = '0'` (`git -C $repoPath commit -m "chore: import the factory kit"`).
- Independently check if `HEAD` is ahead of `origin/main` (`git -C $repoPath rev-list --count origin/main..HEAD`). If ahead (`> 0`), push with `$env:LEFTHOOK = '0'` (`git -C $repoPath push origin main`) so a previously committed-but-unpushed run always converges on rerun.

### Step 5: Write `.local/settings.json` + `datacenter.json` and open VS Code

- If `rg-university-*` already exists in `$SubscriptionId` and `-not $Suffix` and `.local/settings.json` does not exist yet, auto-detect `$Suffix` from `az group list --subscription $SubscriptionId --query "[?starts_with(name,'rg-university-')].name | [0]" -o tsv` so an existing archetype suffix is preserved.
- Run `Join-Path $repoPath 'factory/scripts/Initialize-Settings.ps1'` with `-TenantId $TenantId`, `-SubscriptionId $SubscriptionId`, `-MemberIndex $MemberIndex`, `-Location $Location`, `-WriteLabCredentials`, plus `-SharedSubscriptionId $SharedSubscriptionId` (if detected/supplied) and `-Suffix $Suffix` (if detected/supplied), piping all output through `Protect-SensitiveText`.
- If `-not $SkipOpenCode` and `Get-Command code -ErrorAction SilentlyContinue`, launch `code $repoPath`.

---

## Phase 2: Backwards-Compatible `Test-DevVm.ps1`

- In `infra/datacenter/scripts/Test-DevVm.ps1`, remove `Test-Tool -Name 'node'` and `Test-Tool -Name 'azd'` so `Test-Datacenter.ps1` stays 46/46 PASS on already-provisioned VMs before a student runs `Initialize-Workstation.ps1`.
- Update `test/Test-DevTools.Tests.ps1` to verify `Install-DevTools.ps1` still installs `node` 24 LTS and `azd` for newly provisioned VMs, and update `facilitator/automation-map.md` back to `46 checks`.

---

## Phase 3: Update Onboarding Components and Documentation

1. **`site/src/components/VmDev01Setup.astro`**:
   - Replace the manual multi-step `gh`/`az`/`git clone`/`Initialize-Settings.ps1` sequence with the 1-command `Initialize-Workstation.ps1` bootstrap on `vm-dev01` (plus a collapsible `<details>` block showing the manual commands for reference).
2. **`site/src/content/docs/deploy/lead-setup/student-onboarding.mdx` & `step-4-vending-and-invites.mdx`**:
   - Show the streamlined `Initialize-Workstation.ps1` onboarding flow on `vm-dev01` (where students connect via Bastion and run `Initialize-Workstation.ps1` to auto-detect their environment and create their private repo, or pass `-GitHubOwner <org> -RepoName <assigned-repo>` if their org pre-created repos with `Initialize-CohortRepos.ps1`).
3. **`site/src/content/docs/challenges/index.md`**:
   - Add a callout under **Before you start** with the `Initialize-Workstation.ps1` one-liner for any student whose `vm-dev01` was provisioned before the single-clone update.

---

## Phase 4: Offline End-to-End Automated Test Suite (`test/Test-WorkstationAndImport.Tests.ps1`)

Create `test/Test-WorkstationAndImport.Tests.ps1` (`#Requires -Version 7.4`, standalone `pwsh` script using `Assert-True` like all other `test/*.Tests.ps1` in this repo so `.github/workflows/validate-scripts.yml` runs it on Ubuntu without external test-runner dependencies):

1. **Test 1 — `Import-Kit.ps1` end-to-end against a local tarball and mock `apex-accelerator` repo:**
   - Packs the current repo's required folders (`scripts`, `infra`, `archetype`, `app`, `db`, `templates`, `.github`) into a temporary `.tar.gz` archive.
   - Stubs `Invoke-WebRequest` to copy that `.tar.gz` and runs `scripts/Import-Kit.ps1` against a mock `apex-accelerator` repo.
   - Asserts all root and `factory/` paths, `.github/instructions/contoso-university.instructions.md` (`applyTo: "app/ContosoUniversity/**"`), `.gitattributes` (`*.bicepparam text eol=lf`), `lefthook.yml` exclusions, `.prettierignore`, `weekly-upstream-sync.yml`, and the 5 pre-populated `factory/evidence/` templates, plus `-Force` vs `-ReplaceApp` preservation.
2. **Test 2 — `Initialize-Workstation.ps1` auto-detection, pre-existing VM tool install hook, and repo bootstrap:**
   - Stubs `Get-LocalIPv4Addresses` (`10.10.3.5` -> index `3` and `10.128.1.5` -> index `257`), `gh` (including checking `workflow` scope), `az` (verifying `vnet-datacenter` address space even with a single subscription, and failing closed when `0` or `>1` subscriptions match), `azd`, and the tool installer function.
   - Asserts missing `node`/`azd` triggers the installer, auto-detection resolves `MemberIndex`, `SubscriptionId`, `TenantId`, `Location`, and `SharedSubscriptionId` (from the hub peering resource ID), creates and populates `<WorkspaceRoot>/apex-factory-m03` on `main`, recovers cleanly when a commit exists locally but was not yet pushed, writes `.local/settings.json` and `datacenter.json`, and leaks zero raw GUIDs across all output streams.
3. **Test 3 — `Prepare-MiLinkSource.ps1 -RemoveTraceFlags` behavioral test via extracted helper function:**
   - Extracts a pure function `Remove-SqlStartupTraceFlags` in `infra/datacenter/scripts/Prepare-MiLinkSource.ps1` that takes the current `SQLArg*` map/values and returns the filtered `KeptArgs` and `RemovedArgs`, and parses/executes it in `test/Test-MiLinkSource.Tests.ps1` and `test/Test-WorkstationAndImport.Tests.ps1` on both Linux and Windows without touching real Windows registry keys or services.
   - Asserts that `-T1800` and `-T9567` are removed while `-d`, `-e`, `-l` are preserved in exact order as `SQLArg0..2`.
