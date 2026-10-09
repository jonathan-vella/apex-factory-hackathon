<#
.SYNOPSIS
Places the Arc prep script on vm-app01, without running it.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM. Downloads Prepare-ArcOnAzureVm.ps1 from
the deployment's git ref to C:\LabTools\arc. Members run it themselves before Arc onboarding (C0),
because it turns off the guest agent and so ends run commands.
.PARAMETER PrepScriptUrl
Download URL of Prepare-ArcOnAzureVm.ps1 at the deployment's git ref.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Install-AppArcPrep.ps1 -PrepScriptUrl 'https://raw.githubusercontent.com/<owner>/<repo>/main/infra/datacenter/scripts/Prepare-ArcOnAzureVm.ps1'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $PrepScriptUrl,
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-AppArcPrep.log'
$arcDir = 'C:\LabTools\arc'
$target = Join-Path $arcDir 'Prepare-ArcOnAzureVm.ps1'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    Write-LabLog "Run ID: $RunId"
    New-Item -ItemType Directory -Force -Path $arcDir | Out-Null
    # Download to a temporary file first, so a failed download never leaves a partial script.
    $download = "$target.download"
    Invoke-WebRequest -Uri $PrepScriptUrl -OutFile $download -UseBasicParsing
    Move-Item -Path $download -Destination $target -Force
    Write-LabLog "Placed $target. It isn't run: members run it before Arc onboarding."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
