<#
.SYNOPSIS
Registers a logon step on vm-dev01 that installs the lab's VS Code extensions for every user.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Downloads
Install-DevVSCodeExtensions.ps1 to C:\LabTools\scripts and registers the scheduled task
LabTools-VSCodeExtensions, which runs it as the signed-in user at each logon. Re-running refreshes the
script and the task.
.PARAMETER ScriptsBaseUrl
Base URL of infra/datacenter/scripts at a git ref.
.EXAMPLE
.\Register-DevFirstLogon.ps1 -ScriptsBaseUrl 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ScriptsBaseUrl
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Register-DevFirstLogon.log'
$scriptDir = 'C:\LabTools\scripts'
$taskName = 'LabTools-VSCodeExtensions'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    New-Item -ItemType Directory -Force -Path $scriptDir | Out-Null
    $script = Join-Path $scriptDir 'Install-DevVSCodeExtensions.ps1'
    Invoke-WebRequest -Uri "$ScriptsBaseUrl/Install-DevVSCodeExtensions.ps1" -OutFile $script -UseBasicParsing

    # Users write their logon results to the shared log folder.
    & icacls.exe $logDir /grant '*S-1-5-32-545:(OI)(CI)M' /Q | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "icacls failed on $logDir."
    }

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545' -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-LabLog "Registered ${taskName}: installs the VS Code extensions for each user at logon."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
