#Requires -Version 7.4

<#
.SYNOPSIS
Imports the kit's runnable folders into a member's own apex-accelerator repo, under factory/.
.DESCRIPTION
Downloads this kit at -Ref from GitHub (the tarball REST API; no git clone, no auth needed for the
public repo; it needs api.github.com and codeload.github.com through the firewall) and copies scripts/,
infra/, archetype/, app/, db/, templates/, .github/modernization/ and .github/skills/
into <Destination>/factory/. It then imports the archetype's APEX project into the repo root by
running factory/archetype/Import-Archetype.ps1 at the same -Ref (skip with -SkipArchetype).
factory/.gitignore keeps factory/.local/ (your subscription IDs) out of git. It also installs the platform pipeline's
workflows and actions in the repo's .github/ (they run the kit from factory/; set up with Initialize-PlatformPipeline.ps1). It also keeps factory/ out of the repo's
ESLint, Prettier and markdownlint checks (a nested factory/eslint.config.mjs and factory/.markdownlint-cli2.jsonc, plus a
factory/ line in .prettierignore) and adds factory/ and .prettierignore to the weekly upstream sync's EXCLUDE_PATHS, so
neither the pre-commit hooks nor the sync touch the kit.
Refuses to overwrite an existing factory/ folder unless -Force. -Force replaces only the imported kit
folders: factory/.local (your settings, suffix and datacenter credentials) and your archetype work in the
repo root are kept, unless you also pass -ReplaceArchetype. The site, docs, backlog and coach
material are not imported.
.PARAMETER Ref
The kit's git ref: a branch or commit. Defaults to main.
.PARAMETER KitRepository
The GitHub repository (owner/name) to download the kit from. Defaults to jonathan-vella/apex-factory-hackathon.
An event copy of the kit passes its own owner/name; it must be readable without signing in. It's passed on to
Import-Archetype.ps1. The VMs' scripts are not affected: Deploy-Datacenter.ps1 has its own -Repository.
.PARAMETER Destination
The apex-accelerator repo root to import into. Defaults to the current directory's git root.
.PARAMETER Force
Replace the kit folders in an existing factory/ folder. Keeps factory/.local and your archetype work.
.PARAMETER ReplaceArchetype
With an existing archetype in the repo root (agent-output/university, infra/bicep/university), overwrite
it with the kit's copy. This loses any changes you made to it.
.PARAMETER SkipArchetype
Import factory/ only; don't run the archetype import.
.EXAMPLE
./Import-Kit.ps1
.EXAMPLE
./Import-Kit.ps1 -Ref a1b2c3d -Destination ~/repos/my-apex -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateNotNullOrEmpty()]
    [string] $Ref = 'main',
    [string] $Destination,
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $KitRepository = 'jonathan-vella/apex-factory-hackathon',
    [switch] $Force,
    [switch] $ReplaceArchetype,
    [switch] $SkipArchetype
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$KitOwner, $KitRepo = $KitRepository -split '/'
$ImportItems = @('scripts', 'infra', 'archetype', 'app', 'db', 'templates', '.github/modernization', '.github/skills')

function Add-SyncExclusion {
    # Adds entries to weekly-upstream-sync.yml's EXCLUDE_PATHS block, idempotently.
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string[]]$Entries)

    $warning = "Add $($Entries -join ', ') to EXCLUDE_PATHS in .github/workflows/weekly-upstream-sync.yml yourself, or the next upstream sync reverts or deletes them."
    if (-not (Test-Path $Path)) { Write-Warning "weekly-upstream-sync.yml was not found. $warning"; return }

    $raw = Get-Content -Path $Path -Raw
    $newline = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $raw -split "`r?`n"
    $start = ($lines | Select-String -Pattern '^\s*EXCLUDE_PATHS:\s*\|\s*$' | Select-Object -First 1).LineNumber
    if (-not $start -or $start -ge $lines.Count -or $lines[$start] -notmatch '^(\s+)\S') {
        Write-Warning "weekly-upstream-sync.yml has no recognizable 'EXCLUDE_PATHS: |' block. $warning"
        return
    }
    $indent = $Matches[1]
    $end = $start
    while ($end + 1 -lt $lines.Count -and $lines[$end + 1] -match "^$indent\S") { $end++ }

    $present = $lines[$start..$end] | ForEach-Object { $_.Trim() }
    $missing = @($Entries | Where-Object { $_ -notin $present })
    if (-not $missing) { return }

    $newLines = @($lines[0..$end]) + @($missing | ForEach-Object { "$indent$_" }) + @($lines[($end + 1)..($lines.Count - 1)])
    Set-Content -Path $Path -Value ($newLines -join $newline) -NoNewline
    Write-Host "Added $($missing -join ', ') to EXCLUDE_PATHS in weekly-upstream-sync.yml."
}

if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    throw 'tar was not found on PATH. It ships with Windows 10 1803+, macOS, Linux and the dev container.'
}

if (-not $Destination) {
    $Destination = & git -C (Get-Location) rev-parse --show-toplevel 2>$null
    if (-not $Destination) {
        throw 'Not run inside a git repo and -Destination was not supplied; pass -Destination explicitly.'
    }
}
$Destination = (Resolve-Path $Destination).ProviderPath

if (-not (Test-Path (Join-Path $Destination '.github/agents'))) {
    throw "'$Destination' does not look like an apex-accelerator repo (.github/agents/ not found). Create it from the apex-accelerator template first."
}

$factory = Join-Path $Destination 'factory'
if ((Test-Path $factory) -and -not $Force) {
    throw "'factory/' already exists at '$Destination'. Pass -Force to replace it."
}

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "import-kit-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
try {
    $tarPath = Join-Path $workDir 'kit.tar.gz'
    $extractPath = Join-Path $workDir 'extracted'
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    $uri = "https://api.github.com/repos/$KitOwner/$KitRepo/tarball/$Ref"
    Write-Host "Downloading $KitOwner/$KitRepo@$Ref ..."
    try {
        Invoke-WebRequest -Uri $uri -OutFile $tarPath -UseBasicParsing -Headers @{
            'User-Agent' = 'Import-Kit.ps1'
            'Accept'     = 'application/vnd.github+json'
        }
    }
    catch {
        throw "Could not download $uri (ref '$Ref' may not exist): $($_.Exception.Message)"
    }

    & tar -xzf $tarPath -C $extractPath
    if ($LASTEXITCODE -ne 0) { throw "tar failed to extract $tarPath (exit $LASTEXITCODE)." }

    # The GitHub tarball wraps everything in one top-level <owner>-<repo>-<shortsha>/ directory.
    $kitRoot = (Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1).FullName
    if (-not $kitRoot) { throw "The downloaded archive for ref '$Ref' was empty." }

    foreach ($item in $ImportItems) {
        if (-not (Test-Path (Join-Path $kitRoot $item))) {
            throw "Expected '$item' was not found in $KitOwner/$KitRepo at ref '$Ref'."
        }
    }

    if ($PSCmdlet.ShouldProcess($factory, 'Create factory/ and copy the kit into it')) {
        # Replace only the imported folders, so factory/.local (settings, suffix, datacenter credentials)
        # and anything else you added under factory/ survive a -Force re-import.
        foreach ($item in $ImportItems) {
            $target = Join-Path $factory $item
            if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -Path (Join-Path $kitRoot $item) -Destination $target -Recurse -Force
        }
        Set-Content -Path (Join-Path $factory '.gitignore') -Value ".local/`n" -NoNewline
        Write-Host "Imported the kit at $Ref into '$factory'."

        # The repo's pre-commit hooks lint and format everything staged. The kit isn't written to that style
        # and holds vendored scripts, so keep factory/ out of ESLint, Prettier and markdownlint.
        # ESLint 10 and markdownlint read the nearest config, so factory/ carries its own; Prettier only reads
        # the root .prettierignore.
        $eslintConfig = @'
// The imported kit is not linted: it holds vendored scripts and kit tooling, not this repo's source.
const skip = { meta: { name: "factory-skip" }, preprocess: () => [], postprocess: () => [] };

export default [{ files: ["**/*.js", "**/*.mjs", "**/*.cjs"], processor: skip }];

'@
        Set-Content -Path (Join-Path $factory 'eslint.config.mjs') -Value $eslintConfig -NoNewline
        $markdownRules = (1..60 | ForEach-Object { '    "MD{0:D3}": false' -f $_ }) -join ",`n"
        Set-Content -Path (Join-Path $factory '.markdownlint-cli2.jsonc') -Value "{`n  `"config`": {`n$markdownRules`n  }`n}`n" -NoNewline

        $prettierIgnore = Join-Path $Destination '.prettierignore'
        if (-not (Test-Path $prettierIgnore)) {
            Write-Warning "No .prettierignore at '$Destination'. Add 'factory/' to it yourself, or the pre-commit hooks will format-check the kit."
        }
        elseif (-not ((Get-Content -Path $prettierIgnore -Raw) -match '(?m)^factory/\s*$')) {
            $existing = Get-Content -Path $prettierIgnore -Raw
            $lead = if ($existing.EndsWith("`n")) { '' } else { "`n" }
            Add-Content -Path $prettierIgnore -Value "${lead}`n# Imported kit (Import-Kit.ps1)`nfactory/`n" -NoNewline
        }

        # The weekly upstream sync removes everything upstream doesn't have, except EXCLUDE_PATHS: without
        # factory/ there, it deletes the kit; without .prettierignore, it reverts the line added above.
        Add-SyncExclusion -Path (Join-Path $Destination '.github/workflows/weekly-upstream-sync.yml') -Entries @('factory/', '.prettierignore')

        # The platform pipeline's workflows must sit in the repo root .github/, not in factory/. They run the kit's
        # scripts from factory/ (KIT_DIR), and the sync and Prettier must leave them alone.
        $pipelineWorkflows = @(Get-ChildItem -Path (Join-Path $kitRoot '.github/workflows') -Filter 'platform*.yml' -File -ErrorAction SilentlyContinue)
        if ($pipelineWorkflows.Count -gt 0) {
            $workflowsTarget = Join-Path $Destination '.github/workflows'
            New-Item -ItemType Directory -Path $workflowsTarget -Force | Out-Null
            foreach ($workflow in $pipelineWorkflows) {
                $text = (Get-Content -Path $workflow.FullName -Raw) -replace '(?m)^(\s*KIT_DIR:\s*)\.\s*$', '${1}factory'
                # The VMs download their scripts from the public kit, not from the attendee's (possibly private) repo.
                $text = $text -replace '(?m)^(\s*KIT_REPOSITORY:).*$', "`${1} $KitRepository"
                $text = $text -replace '(?m)^(\s*KIT_REF:).*$', "`${1} $Ref"
                Set-Content -Path (Join-Path $workflowsTarget $workflow.Name) -Value $text -NoNewline
            }
            foreach ($action in 'guard', 'platform-session') {
                $actionTarget = Join-Path $Destination ".github/actions/$action"
                if (Test-Path $actionTarget) { Remove-Item -Path $actionTarget -Recurse -Force }
                New-Item -ItemType Directory -Path (Split-Path $actionTarget -Parent) -Force | Out-Null
                Copy-Item -Path (Join-Path $kitRoot ".github/actions/$action") -Destination $actionTarget -Recurse -Force
            }
            $pipelineEntries = @($pipelineWorkflows | ForEach-Object { ".github/workflows/$($_.Name)" }) + @('.github/actions/guard/', '.github/actions/platform-session/')
            Add-SyncExclusion -Path (Join-Path $Destination '.github/workflows/weekly-upstream-sync.yml') -Entries $pipelineEntries
            if (Test-Path $prettierIgnore) {
                $existing = Get-Content -Path $prettierIgnore -Raw
                $missingIgnore = @($pipelineEntries | Where-Object { $existing -notmatch "(?m)^$([regex]::Escape($_))\s*$" })
                if ($missingIgnore) {
                    $lead = if ($existing.EndsWith("`n")) { '' } else { "`n" }
                    Add-Content -Path $prettierIgnore -Value "${lead}`n# Platform pipeline (Import-Kit.ps1)`n$($missingIgnore -join "`n")`n" -NoNewline
                }
            }
            Write-Information "Installed the platform pipeline workflows in .github/ (they run the kit from factory/). Set it up with ./scripts/Initialize-PlatformPipeline.ps1." -InformationAction Continue
        }
    }

    if (-not $SkipArchetype) {
        $archetypeImport = Join-Path $factory 'archetype/Import-Archetype.ps1'
        $archetypeExists = (Test-Path (Join-Path $Destination 'agent-output/university')) -or (Test-Path (Join-Path $Destination 'infra/bicep/university'))
        if ($archetypeExists -and -not $ReplaceArchetype) {
            Write-Warning "Kept your existing archetype (agent-output/university and infra/bicep/university). Pass -ReplaceArchetype to overwrite it with the kit's copy and lose your changes."
        }
        elseif ($PSCmdlet.ShouldProcess($Destination, 'Import the archetype into the repo root')) {
            $archetypeArguments = @{ Ref = $Ref; Destination = $Destination; Force = $ReplaceArchetype }
            if ($KitRepository -ne 'jonathan-vella/apex-factory-hackathon') { $archetypeArguments['KitRepository'] = $KitRepository }
            & $archetypeImport @archetypeArguments
        }
    }

    Write-Host ''
    Write-Host 'Next, as Prerequisites describes: commit this import to a new branch, sign in with az login, then run ./scripts/Initialize-Settings.ps1 from the factory folder.'
}
finally {
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
