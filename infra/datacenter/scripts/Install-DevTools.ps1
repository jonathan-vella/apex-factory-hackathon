<#
.SYNOPSIS
Installs the developer tools on vm-dev01, machine-wide and silently.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Creates C:\src, then installs VS Code
(system installer), Git, the GitHub CLI, PowerShell 7, the Azure CLI, Bicep (standalone), Node.js 24 LTS,
Python 3, the Azure Developer CLI (azd), the .NET 10 SDK, the .NET Framework 4.8 Developer Pack and the NuGet CLI
from the vendors' official download locations. Tools that are already installed are skipped. Finally it clones the kit (public repo) to
C:\src\factory if it isn't there yet, as a sparse checkout (non-cone patterns) that leaves out coach/,
facilitator/, docs/, site/, test/ and the repo's documentation and lint tooling files. Everything the
attendees use stays: app/, db/, scripts/, infra/, archetype/, templates/, .github/, README.md, LICENSE and
NOTICE. The full history is still in .git: the patterns only keep the files out of the working tree. The
clone step is skipped when C:\src\factory\.git exists, and this run command runs again on every
deployment, so an existing clone is never changed: a VM deployed before this change keeps its full
checkout until the commands in infra/datacenter/README.md ("Slim an existing clone") are applied.
Build Tools and SSMS have their own scripts.
Exit code 3010 (restart required) is logged and ignored: the lab doesn't need a restart.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Install-DevTools.ps1
#>
[CmdletBinding()]
param(
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-DevTools.log'
$downloadDir = 'C:\LabTools\downloads'
$pwshDir = 'C:\Program Files\PowerShell\7'
$bicepDir = 'C:\Program Files\Bicep'
$nodeDir = 'C:\Program Files\nodejs'
$pythonDir = 'C:\Program Files\Python3'
$azdDir = 'C:\Program Files\Azure Dev CLI'
$nugetDir = 'C:\Program Files\NuGet'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Get-Download {
    param([string] $Url, [string] $FileName)
    $path = Join-Path $downloadDir $FileName
    Invoke-WebRequest -Uri $Url -OutFile $path -UseBasicParsing
    return $path
}

function Get-GitHubAssetUrl {
    param([string] $Repository, [string] $Pattern)
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -UseBasicParsing
    $asset = $release.assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
    if (-not $asset) {
        throw "No asset matching '$Pattern' in the latest $Repository release."
    }
    return $asset.browser_download_url
}

function Invoke-Installer {
    param([string] $Name, [string] $FilePath, [string[]] $ArgumentList)
    Write-LabLog "Installing $Name."
    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden
    $null = $process.Handle
    $process.WaitForExit()
    switch ($process.ExitCode) {
        0 { Write-LabLog "$Name installed." }
        3010 { Write-LabLog "$Name installed. It asked for a restart (3010): not restarting, the lab doesn't need it." }
        default { throw "$Name installer failed with exit code $($process.ExitCode)." }
    }
}

function Install-Msi {
    param([string] $Name, [string] $Path, [string[]] $Properties = @())
    Invoke-Installer -Name $Name -FilePath 'msiexec.exe' -ArgumentList (@('/i', "`"$Path`"", '/qn', '/norestart') + $Properties)
}

function Add-MachinePath {
    param([string] $Directory)
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (($machinePath -split ';') -notcontains $Directory) {
        [Environment]::SetEnvironmentVariable('Path', "$machinePath;$Directory", 'Machine')
        Write-LabLog "Added $Directory to the machine PATH."
    }
}

try {
    Write-LabLog "Run ID: $RunId"
    New-Item -ItemType Directory -Force -Path 'C:\src', $downloadDir | Out-Null

    if (-not (Test-Path 'C:\Program Files\Microsoft VS Code\Code.exe')) {
        $file = Get-Download -Url 'https://update.code.visualstudio.com/latest/win32-x64/stable' -FileName 'VSCodeSetup-x64.exe'
        Invoke-Installer -Name 'Visual Studio Code' -FilePath $file -ArgumentList '/VERYSILENT', '/NORESTART', '/MERGETASKS=!runcode,addtopath'
    }

    if (-not (Test-Path 'C:\Program Files\Git\cmd\git.exe')) {
        $url = Get-GitHubAssetUrl -Repository 'git-for-windows/git' -Pattern '^Git-[\d.]+-64-bit\.exe$'
        $file = Get-Download -Url $url -FileName 'Git-64-bit.exe'
        Invoke-Installer -Name 'Git' -FilePath $file -ArgumentList '/VERYSILENT', '/NORESTART', '/NOCANCEL', '/SP-', '/SUPPRESSMSGBOXES'
    }

    if (-not (Test-Path 'C:\Program Files\GitHub CLI\gh.exe')) {
        $url = Get-GitHubAssetUrl -Repository 'cli/cli' -Pattern '_windows_amd64\.msi$'
        $file = Get-Download -Url $url -FileName 'gh_windows_amd64.msi'
        Install-Msi -Name 'GitHub CLI' -Path $file
    }

    $pwshExe = Join-Path $pwshDir 'pwsh.exe'
    if (-not (Test-Path $pwshExe)) {
        # PowerShell 7.7+ ships no MSI, and Add-AppxPackage cannot run as SYSTEM; install the official zip archive.
        $url = Get-GitHubAssetUrl -Repository 'PowerShell/PowerShell' -Pattern '^PowerShell-[\d.]+-win-x64\.zip$'
        $file = Get-Download -Url $url -FileName 'PowerShell-win-x64.zip'
        if (Test-Path $pwshDir) {
            Remove-Item -LiteralPath $pwshDir -Recurse -Force
        }
        New-Item -ItemType Directory -Force -Path $pwshDir | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($file, $pwshDir)
        $shortcutDir = 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerShell'
        New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null
        $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $shortcutDir 'PowerShell 7 (x64).lnk'))
        $shortcut.TargetPath = $pwshExe
        $shortcut.WorkingDirectory = '%HOMEDRIVE%%HOMEPATH%'
        $shortcut.Save()
        Write-LabLog 'PowerShell 7 installed.'
    }
    Add-MachinePath -Directory $pwshDir

    if (-not (Test-Path 'C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd')) {
        $file = Get-Download -Url 'https://aka.ms/installazurecliwindowsx64' -FileName 'azure-cli-x64.msi'
        Install-Msi -Name 'Azure CLI' -Path $file
    }

    if (-not (Test-Path (Join-Path $bicepDir 'bicep.exe'))) {
        New-Item -ItemType Directory -Force -Path $bicepDir | Out-Null
        Invoke-WebRequest -Uri 'https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe' -OutFile (Join-Path $bicepDir 'bicep.exe') -UseBasicParsing
        Write-LabLog 'Bicep installed.'
    }
    Add-MachinePath -Directory $bicepDir

    if (-not (Test-Path (Join-Path $nodeDir 'node.exe'))) {
        $nodeReleases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
        $node24 = $nodeReleases | Where-Object { $_.version -match '^v24\.' -and $_.lts } | Select-Object -First 1
        if (-not $node24) {
            throw 'No Node.js 24 LTS release found in https://nodejs.org/dist/index.json.'
        }
        $nodeMsiUrl = "https://nodejs.org/dist/$($node24.version)/node-$($node24.version)-x64.msi"
        $file = Get-Download -Url $nodeMsiUrl -FileName "node-$($node24.version)-x64.msi"
        Install-Msi -Name "Node.js $($node24.version)" -Path $file
    }
    Add-MachinePath -Directory $nodeDir

    if (-not (Test-Path (Join-Path $pythonDir 'python.exe'))) {
        $pythonPage = (Invoke-WebRequest -Uri 'https://www.python.org/downloads/windows/' -UseBasicParsing).Content
        $pythonMatch = [regex]::Match($pythonPage, 'https://www\.python\.org/ftp/python/(3\.\d+\.\d+)/python-\1-amd64\.exe')
        if (-not $pythonMatch.Success) {
            throw 'No Python 3 Windows x64 installer found at https://www.python.org/downloads/windows/.'
        }
        $pythonVersion = $pythonMatch.Groups[1].Value
        $file = Get-Download -Url $pythonMatch.Value -FileName "python-$pythonVersion-amd64.exe"
        Invoke-Installer -Name "Python $pythonVersion" -FilePath $file -ArgumentList '/quiet', 'InstallAllUsers=1', 'PrependPath=1', 'Include_test=0', "TargetDir=`"$pythonDir`""
    }
    # The official Windows installer ships python.exe but not python3.exe; copy the launcher stub
    # so `python3` resolves here ahead of the Windows 11 Microsoft Store alias in WindowsApps.
    if ((Test-Path (Join-Path $pythonDir 'python.exe')) -and -not (Test-Path (Join-Path $pythonDir 'python3.exe'))) {
        Copy-Item -Path (Join-Path $pythonDir 'python.exe') -Destination (Join-Path $pythonDir 'python3.exe') -Force
    }
    Add-MachinePath -Directory $pythonDir
    Add-MachinePath -Directory (Join-Path $pythonDir 'Scripts')

    if (-not (Test-Path (Join-Path $azdDir 'azd.exe'))) {
        $file = Get-Download -Url 'https://azuresdkartifacts.z5.web.core.windows.net/azd/standalone/release/stable/azd-windows-amd64.msi' -FileName 'azd-windows-amd64.msi'
        Install-Msi -Name 'Azure Developer CLI (azd)' -Path $file -Properties @('ALLUSERS=1')
    }
    Add-MachinePath -Directory $azdDir

    if (-not (Test-Path 'C:\Program Files\dotnet\sdk\10.*')) {
        $file = Get-Download -Url 'https://aka.ms/dotnet/10.0/dotnet-sdk-win-x64.exe' -FileName 'dotnet-sdk-10-win-x64.exe'
        Invoke-Installer -Name '.NET 10 SDK' -FilePath $file -ArgumentList '/install', '/quiet', '/norestart'
    }

    if (-not (Test-Path 'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\mscorlib.dll')) {
        $file = Get-Download -Url 'https://go.microsoft.com/fwlink/?linkid=2088517' -FileName 'ndp48-devpack-enu.exe'
        Invoke-Installer -Name '.NET Framework 4.8 Developer Pack' -FilePath $file -ArgumentList '/q', '/norestart'
    }

    if (-not (Test-Path (Join-Path $nugetDir 'nuget.exe'))) {
        New-Item -ItemType Directory -Force -Path $nugetDir | Out-Null
        Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile (Join-Path $nugetDir 'nuget.exe') -UseBasicParsing
        Write-LabLog 'NuGet CLI installed.'
    }
    Add-MachinePath -Directory $nugetDir

    # Clone as SYSTEM, so mark the folder safe for the lab user. Re-runs leave the clone untouched, so an
    # existing clone keeps its full checkout: infra/datacenter/README.md has the commands to slim it down.
    # The sparse patterns keep the coach and event-owner material out of the working tree (not out of .git).
    # Keep this list in sync with the README; test/Test-DevSparse.Tests.ps1 compares them.
    $git = 'C:\Program Files\Git\cmd\git.exe'
    $kitDir = 'C:\src\factory'
    $kitSparsePatterns = @(
        '/*'
        '!/coach/'
        '!/facilitator/'
        '!/docs/'
        '!/site/'
        '!/test/'
        '!/.vale/'
        '!/.vale.ini'
        '!/.markdownlint-cli2.mjs'
        '!/.prettierignore'
        '!/prettier.config.mjs'
        '!/lefthook.yml'
        '!/package.json'
        '!/package-lock.json'
        '!/.node-version'
        '!/.nvmrc'
    )
    if (-not (Test-Path (Join-Path $kitDir '.git'))) {
        try {
            & $git clone --quiet --no-checkout https://github.com/jonathan-vella/apex-factory-hackathon.git $kitDir
            if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE." }
            & $git -C $kitDir sparse-checkout set --no-cone @kitSparsePatterns
            if ($LASTEXITCODE -ne 0) { throw "git sparse-checkout failed with exit code $LASTEXITCODE." }
            & $git -C $kitDir checkout --quiet
            if ($LASTEXITCODE -ne 0) { throw "git checkout failed with exit code $LASTEXITCODE." }
        }
        catch {
            # A half-made clone would be skipped on the next run, so remove it.
            Remove-Item -LiteralPath $kitDir -Recurse -Force -ErrorAction SilentlyContinue
            throw
        }
        Write-LabLog "Cloned the kit to $kitDir without the coach and facilitator material (sparse checkout)."
    }
    & $git config --system --replace-all safe.directory 'C:/src/factory'

    Write-LabLog 'Developer tools are installed.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
