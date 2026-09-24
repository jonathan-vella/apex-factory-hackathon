<#
.SYNOPSIS
Installs Visual Studio Build Tools (current release) with the web build tools workload on vm-dev01.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Installs the
Microsoft.VisualStudio.Workload.WebBuildTools workload with its recommended components, which the
legacy web application project needs. Skipped if that workload is already installed. Exit code 3010
(restart required) is logged and ignored.
.EXAMPLE
.\Install-DevBuildTools.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-DevBuildTools.log'
$downloadDir = 'C:\LabTools\downloads'
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
$workload = 'Microsoft.VisualStudio.Workload.WebBuildTools'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Get-BuildToolsPath {
    if (-not (Test-Path $vswhere)) {
        return $null
    }
    return (& $vswhere -products 'Microsoft.VisualStudio.Product.BuildTools' -requires $workload -property installationPath | Select-Object -First 1)
}

function Wait-VsInstaller {
    # A second run of this script must not start an install while another is still running.
    $names = 'vs_SSMS*', 'vs_BuildTools*', 'vs_setup_bootstrapper', 'vs_installer', 'vs_installershell'
    for ($i = 0; Get-Process -Name $names -ErrorAction SilentlyContinue; $i++) {
        if ($i -eq 0) { Write-LabLog 'Waiting for a running Visual Studio installer to finish.' }
        if ($i -ge 360) { throw 'A Visual Studio installer is still running after 60 minutes.' }
        Start-Sleep -Seconds 10
    }
}

try {
    New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
    Wait-VsInstaller
    if (Get-BuildToolsPath) {
        Write-LabLog "Build Tools with $workload are already installed."
        exit 0
    }

    $bootstrapper = Join-Path $downloadDir 'vs_BuildTools.exe'
    Invoke-WebRequest -Uri 'https://aka.ms/vs/stable/vs_BuildTools.exe' -OutFile $bootstrapper -UseBasicParsing
    Write-LabLog "Installing Build Tools with $workload and its recommended components."
    $arguments = '--quiet', '--wait', '--norestart', '--nocache', '--add', $workload, '--includeRecommended'
    $process = Start-Process -FilePath $bootstrapper -ArgumentList $arguments -PassThru -WindowStyle Hidden
    $null = $process.Handle
    $process.WaitForExit()
    switch ($process.ExitCode) {
        0 { Write-LabLog 'Build Tools installed.' }
        3010 { Write-LabLog "Build Tools installed. It asked for a restart (3010): not restarting, the lab doesn't need it." }
        default { throw "Build Tools installer failed with exit code $($process.ExitCode)." }
    }

    $path = Get-BuildToolsPath
    if (-not $path) {
        throw "Build Tools installed, but vswhere doesn't find $workload."
    }
    Write-LabLog "Build Tools are at $path."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
