#Requires -Version 7.4

<#
.SYNOPSIS
Imports the kit's runnable folders into a member's own apex-accelerator repo, under factory/.
.DESCRIPTION
Downloads this kit at -Ref from GitHub (the tarball REST API; no git clone, no auth needed for the
public repo) and copies scripts/, infra/, archetype/, app/, db/, templates/, .github/modernization/ and .github/skills/
into <Destination>/factory/. It then imports the archetype's APEX project into the repo root by
running factory/archetype/Import-Archetype.ps1 at the same -Ref (skip with -SkipArchetype).
factory/.gitignore keeps factory/.local/ (your subscription IDs) out of git.
Refuses to overwrite an existing factory/ folder unless -Force. The site, docs, backlog and coach
material are not imported.
.PARAMETER Ref
The kit's git ref (jonathan-vella/apex-factory-hackathon): a branch, tag or commit. Defaults to main.
.PARAMETER Destination
The apex-accelerator repo root to import into. Defaults to the current directory's git root.
.PARAMETER Force
Replace an existing factory/ folder.
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
    [switch] $Force,
    [switch] $SkipArchetype
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$KitOwner = 'jonathan-vella'
$KitRepo = 'apex-factory-hackathon'
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
        if (Test-Path $factory) { Remove-Item -Path $factory -Recurse -Force }
        foreach ($item in $ImportItems) {
            $target = Join-Path $factory $item
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -Path (Join-Path $kitRoot $item) -Destination $target -Recurse -Force
        }
        Set-Content -Path (Join-Path $factory '.gitignore') -Value ".local/`n" -NoNewline
        Write-Host "Imported the kit at $Ref into '$factory'."
    }

    if (-not $SkipArchetype) {
        $archetypeImport = Join-Path $factory 'archetype/Import-Archetype.ps1'
        if ($PSCmdlet.ShouldProcess($Destination, 'Import the archetype into the repo root')) {
            & $archetypeImport -Ref $Ref -Destination $Destination -Force:$Force
        }
    }

    Write-Host ''
    Write-Host 'Next: cd factory, run ./scripts/Initialize-Settings.ps1, then the C0 scripts from there.'
}
finally {
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
