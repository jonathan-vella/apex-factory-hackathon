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
factory/.gitignore keeps factory/.local/ (your subscription IDs) out of git.
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
    Write-Host 'Next: cd factory, run ./scripts/Initialize-Settings.ps1, then the C0 scripts from there.'
}
finally {
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
