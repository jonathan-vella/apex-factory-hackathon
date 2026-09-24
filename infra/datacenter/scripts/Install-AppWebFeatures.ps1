<#
.SYNOPSIS
Installs IIS with ASP.NET 4.8 and the MSMQ server feature on vm-app01.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1). Features that are already installed are skipped.
If Windows asks for a restart, the script logs it and carries on: the lab doesn't need one.
.EXAMPLE
.\Install-AppWebFeatures.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-AppWebFeatures.log'
$features = 'Web-Server', 'Web-Asp-Net45', 'MSMQ-Server'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    $missing = @(Get-WindowsFeature -Name $features | Where-Object { -not $_.Installed } | ForEach-Object Name)
    if ($missing.Count -eq 0) {
        Write-LabLog "Already installed: $($features -join ', ')."
        exit 0
    }

    Write-LabLog "Installing: $($missing -join ', ')."
    $result = Install-WindowsFeature -Name $missing -IncludeManagementTools
    if (-not $result.Success) {
        throw "Install-WindowsFeature failed with exit code $($result.ExitCode)."
    }
    if ($result.RestartNeeded -ne 'No') {
        Write-LabLog "Windows reports RestartNeeded=$($result.RestartNeeded). Not restarting: the lab doesn't need it."
    }
    Write-LabLog "Installed: $($result.FeatureResult.Name -join ', ')."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
