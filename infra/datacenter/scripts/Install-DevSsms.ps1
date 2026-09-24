<#
.SYNOPSIS
Installs SQL Server Management Studio 22 on vm-dev01.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, after Build Tools: both use the Visual
Studio installer, which runs one install at a time. Skipped if SSMS 22 is already installed.
Exit code 3010 (restart required) is logged and ignored.
.EXAMPLE
.\Install-DevSsms.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-DevSsms.log'
$downloadDir = 'C:\LabTools\downloads'
$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Get-SsmsPath {
    if (-not (Test-Path $vswhere)) {
        return $null
    }
    return (& $vswhere -products 'Microsoft.VisualStudio.Product.SSMS' -property installationPath | Select-Object -First 1)
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
    if (Get-SsmsPath) {
        Write-LabLog 'SSMS 22 is already installed.'
        exit 0
    }

    # A unique name avoids a lock on a previous download (seen on the first validation run).
    $bootstrapper = Join-Path $downloadDir "vs_SSMS-$([guid]::NewGuid().ToString('N')).exe"
    Invoke-WebRequest -Uri 'https://aka.ms/ssms/22/release/vs_SSMS.exe' -OutFile $bootstrapper -UseBasicParsing
    Write-LabLog 'Installing SSMS 22.'
    $process = Start-Process -FilePath $bootstrapper -ArgumentList '--quiet', '--wait', '--norestart', '--nocache' -PassThru -WindowStyle Hidden
    $null = $process.Handle
    $process.WaitForExit()
    switch ($process.ExitCode) {
        0 { Write-LabLog 'SSMS 22 installed.' }
        3010 { Write-LabLog "SSMS 22 installed. It asked for a restart (3010): not restarting, the lab doesn't need it." }
        default { throw "SSMS installer failed with exit code $($process.ExitCode)." }
    }

    $path = Get-SsmsPath
    if (-not $path) {
        throw "SSMS installed, but vswhere doesn't find it."
    }
    Write-LabLog "SSMS 22 is at $path."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
