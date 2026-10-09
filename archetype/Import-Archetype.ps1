#Requires -Version 7.4

<#
.SYNOPSIS
Imports the CoE archetype's APEX project into a member's own apex-accelerator repo, in one command.
.DESCRIPTION
Downloads this kit's archetype/ folder at -Ref straight from GitHub (the tarball REST API; no git
clone, no auth needed for the public repo), and copies agent-output/university/,
infra/bicep/university/ and .github/prompts/adapt-archetype.prompt.md into the matching paths of
-Destination, which must already be an apex-accelerator repo (checked by .github/agents/ existing).
It also adds .github/prompts/adapt-archetype.prompt.md to -Destination's
.github/workflows/weekly-upstream-sync.yml EXCLUDE_PATHS list (idempotently), because that prompt
is accelerator-specific and the weekly upstream sync would otherwise delete it the first time it
runs (apex-accelerator's .github/prompts/ is synced from upstream, upstream wins). Refuses to
overwrite an existing university project unless -Force. Reports a file count and a byte-level
content hash over the copied infra/bicep/university/ tree so the member can compare it against the
archetype's packaged tree hash -- a mismatch there is a known, already-documented drift (see
archetype/README.md and PR #51), not something this script tries to resolve.
.PARAMETER Ref
The kit's git tag or commit to import archetype/ from (jonathan-vella/apex-factory-hackathon).
Mandatory: there is no "main" default, so an import is always pinned to a specific point in time.
.PARAMETER Destination
The apex-accelerator repo root to import into. Defaults to the current directory's git root.
.PARAMETER Force
Overwrite an existing university project at the destination (agent-output/university/ and/or
infra/bicep/university/ already present). Without it, the script refuses rather than merge trees.
.EXAMPLE
./archetype/Import-Archetype.ps1 -Ref v1.2.0
.EXAMPLE
./archetype/Import-Archetype.ps1 -Ref a1b2c3d -Destination C:\repos\my-apex-accelerator -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Ref,
    [string] $Destination,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$KitOwner = 'jonathan-vella'
$KitRepo = 'apex-factory-hackathon'
$ImportItems = @(
    [PSCustomObject]@{ RelativePath = 'agent-output/university'; IsDirectory = $true }
    [PSCustomObject]@{ RelativePath = 'infra/bicep/university'; IsDirectory = $true }
    [PSCustomObject]@{ RelativePath = '.github/prompts/adapt-archetype.prompt.md'; IsDirectory = $false }
)
$SyncWorkflowRelativePath = '.github/workflows/weekly-upstream-sync.yml'
$SyncProtectedPath = '.github/prompts/adapt-archetype.prompt.md'

function ConvertTo-NativePath {
    # Joins forward-slash relative paths the same way on every platform.
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RelativePath)
    Join-Path -Path $Root -ChildPath ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Get-KitArchetypeArchive {
    # Downloads and extracts this kit's archetype/ folder at $Ref via the GitHub tarball API (no git, no auth).
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Ref, [Parameter(Mandatory)][string]$WorkDir)

    if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
        throw 'tar was not found on PATH. It ships with Windows 10 1803+, macOS, Linux and Azure Cloud Shell; install it or run this script somewhere it is available.'
    }

    $tarPath = Join-Path $WorkDir 'kit.tar.gz'
    $extractPath = Join-Path $WorkDir 'extracted'
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

    $uri = "https://api.github.com/repos/$KitOwner/$KitRepo/tarball/$Ref"
    Write-Host "Downloading $KitOwner/$KitRepo@$Ref ..."
    try {
        Invoke-WebRequest -Uri $uri -OutFile $tarPath -UseBasicParsing -Headers @{
            'User-Agent' = 'Import-Archetype.ps1'
            'Accept'     = 'application/vnd.github+json'
        }
    }
    catch {
        throw "Could not download $uri (ref '$Ref' may not exist): $($_.Exception.Message)"
    }

    & tar -xzf $tarPath -C $extractPath
    if ($LASTEXITCODE -ne 0) { throw "tar failed to extract $tarPath (exit $LASTEXITCODE)." }

    # The GitHub tarball wraps everything in a single top-level <owner>-<repo>-<shortsha>/ directory.
    $topLevel = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    if (-not $topLevel) { throw "The downloaded archive for ref '$Ref' was empty." }

    $archetypeRoot = Join-Path $topLevel.FullName 'archetype'
    if (-not (Test-Path $archetypeRoot)) {
        throw "No archetype/ folder found in $KitOwner/$KitRepo at ref '$Ref'."
    }
    return $archetypeRoot
}

function Get-DirectoryContentHash {
    # A byte-level content hash over a directory tree: SHA256 of each file's relative path (forward
    # slashes, sorted) concatenated with its raw bytes. This is this script's own check, not
    # necessarily identical to APEX's own tree_hash algorithm -- it exists so a member can tell
    # whether their copy's bytes match the kit ref they imported, nothing more.
    param([Parameter(Mandatory)][string]$Path)
    $files = Get-ChildItem -Path $Path -Recurse -File | Sort-Object { $_.FullName.Replace('\', '/') }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.MemoryStream]::new()
        foreach ($file in $files) {
            $relative = [IO.Path]::GetRelativePath($Path, $file.FullName).Replace('\', '/')
            $nameBytes = [System.Text.Encoding]::UTF8.GetBytes($relative)
            $stream.Write($nameBytes, 0, $nameBytes.Length)
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $stream.Write($fileBytes, 0, $fileBytes.Length)
        }
        $hash = $sha256.ComputeHash($stream.ToArray())
        return [PSCustomObject]@{
            FileCount = $files.Count
            Hash      = ([System.BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
        }
    }
    finally {
        $sha256.Dispose()
    }
}

function Copy-ArchetypeItem {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$DestinationRoot,
        [Parameter(Mandatory)]$Item,
        [switch]$Force
    )
    $source = ConvertTo-NativePath -Root $SourceRoot -RelativePath $Item.RelativePath
    $destination = ConvertTo-NativePath -Root $DestinationRoot -RelativePath $Item.RelativePath
    if (-not (Test-Path $source)) { throw "Expected '$($Item.RelativePath)' was not found in the downloaded archive." }

    if (Test-Path $destination) {
        if (-not $Force) {
            throw "'$($Item.RelativePath)' already exists at the destination. Pass -Force to overwrite it."
        }
        if ($PSCmdlet.ShouldProcess($destination, 'Remove existing item before overwrite')) {
            Remove-Item -Path $destination -Recurse -Force
        }
    }

    $destinationParent = Split-Path -Path $destination -Parent
    if ($PSCmdlet.ShouldProcess($destinationParent, 'Create parent directory')) {
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    }
    if ($PSCmdlet.ShouldProcess($destination, 'Copy from downloaded archive')) {
        Copy-Item -Path $source -Destination $destination -Recurse -Force
    }
}

function Set-SyncProtectionExclusion {
    # Adds $SyncProtectedPath to weekly-upstream-sync.yml's EXCLUDE_PATHS block, idempotently, so
    # the upstream sync (which otherwise takes .github/prompts/ entirely from upstream) does not
    # delete the member's copy of the adapt-archetype prompt on its next run.
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$ProtectedPath)

    if (-not (Test-Path $Path)) {
        Write-Warning "$SyncWorkflowRelativePath was not found at the destination. Add '$ProtectedPath' to its EXCLUDE_PATHS yourself, or the next upstream sync will delete the imported prompt."
        return
    }

    $raw = Get-Content -Path $Path -Raw
    $newline = if ($raw -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $raw -split "`r?`n"

    $blockStart = ($lines | Select-String -Pattern '^\s*EXCLUDE_PATHS:\s*\|\s*$' | Select-Object -First 1).LineNumber
    if (-not $blockStart) {
        Write-Warning "$SyncWorkflowRelativePath has no 'EXCLUDE_PATHS: |' block. Add '$ProtectedPath' to it yourself, or the next upstream sync will delete the imported prompt."
        return
    }

    $blockStartIndex = $blockStart - 1
    $firstItemIndex = $blockStartIndex + 1
    if ($firstItemIndex -ge $lines.Count -or $lines[$firstItemIndex] -notmatch '^(\s+)\S') {
        Write-Warning "$SyncWorkflowRelativePath's EXCLUDE_PATHS block is empty or unrecognized. Add '$ProtectedPath' to it yourself."
        return
    }
    $indent = $Matches[1]

    $endIndex = $firstItemIndex
    while ($endIndex + 1 -lt $lines.Count -and $lines[$endIndex + 1] -match "^$indent\S") {
        $endIndex++
    }
    $blockLines = $lines[$firstItemIndex..$endIndex]
    if ($blockLines | Where-Object { $_.Trim() -eq $ProtectedPath }) {
        Write-Host "$ProtectedPath is already excluded from upstream sync."
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, "Add '$ProtectedPath' to EXCLUDE_PATHS")) {
        $newLines = @($lines[0..$endIndex]) + "$indent$ProtectedPath" + @($lines[($endIndex + 1)..($lines.Count - 1)])
        Set-Content -Path $Path -Value ($newLines -join $newline) -NoNewline
        Write-Host "Added '$ProtectedPath' to EXCLUDE_PATHS in $SyncWorkflowRelativePath."
    }
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

foreach ($item in $ImportItems) {
    $existing = ConvertTo-NativePath -Root $Destination -RelativePath $item.RelativePath
    if ((Test-Path $existing) -and -not $Force) {
        throw "'$($item.RelativePath)' already exists at '$Destination'. Pass -Force to overwrite an existing university project."
    }
}

$workDir = Join-Path ([System.IO.Path]::GetTempPath()) "import-archetype-$([guid]::NewGuid())"
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
try {
    $archetypeRoot = Get-KitArchetypeArchive -Ref $Ref -WorkDir $workDir

    foreach ($item in $ImportItems) {
        Copy-ArchetypeItem -SourceRoot $archetypeRoot -DestinationRoot $Destination -Item $item -Force:$Force
    }

    $destBicepRoot = ConvertTo-NativePath -Root $Destination -RelativePath 'infra/bicep/university'
    $sourceBicepRoot = ConvertTo-NativePath -Root $archetypeRoot -RelativePath 'infra/bicep/university'
    if (Test-Path $destBicepRoot) {
        $sourceCheck = Get-DirectoryContentHash -Path $sourceBicepRoot
        $destCheck = Get-DirectoryContentHash -Path $destBicepRoot
        Write-Host "infra/bicep/university/: $($destCheck.FileCount) files copied (archive had $($sourceCheck.FileCount))."
        if ($destCheck.FileCount -ne $sourceCheck.FileCount) {
            Write-Warning 'File count differs between the archive and the copy -- the copy step above may not have completed.'
        }
        Write-Host "Content hash (this script's own byte check, not APEX's tree_hash): $($destCheck.Hash)"
        Write-Host "Compare this against the packaged value in archetype/README.md -- a mismatch there is a known, already-documented drift, not something this script resolves."
    }

    Set-SyncProtectionExclusion -Path (ConvertTo-NativePath -Root $Destination -RelativePath $SyncWorkflowRelativePath) -ProtectedPath $SyncProtectedPath

    Write-Host ''
    Write-Host "Imported archetype/ from $KitOwner/$KitRepo@$Ref into '$Destination'."
    Write-Host 'Next: open this repo in VS Code and run /adapt-archetype in Agent mode.'
}
finally {
    Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
