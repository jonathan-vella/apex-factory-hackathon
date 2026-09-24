<#
.SYNOPSIS
Installs the developer tools on vm-dev01, machine-wide and silently.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Creates C:\src, then installs VS Code
(system installer), Git, the GitHub CLI, PowerShell 7, the Azure CLI, Bicep (standalone), the .NET 10
SDK, the .NET Framework 4.8 Developer Pack and the NuGet CLI from the vendors' official download
locations. Tools that are already installed are skipped. Build Tools and SSMS have their own scripts.
Exit code 3010 (restart required) is logged and ignored: the lab doesn't need a restart.
.EXAMPLE
.\Install-DevTools.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-DevTools.log'
$downloadDir = 'C:\LabTools\downloads'
$bicepDir = 'C:\Program Files\Bicep'
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

    if (-not (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe')) {
        $url = Get-GitHubAssetUrl -Repository 'PowerShell/PowerShell' -Pattern '^PowerShell-[\d.]+-win-x64\.msi$'
        $file = Get-Download -Url $url -FileName 'PowerShell-win-x64.msi'
        Install-Msi -Name 'PowerShell 7' -Path $file -Properties 'ADD_PATH=1'
    }

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

    Write-LabLog 'Developer tools are installed.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
