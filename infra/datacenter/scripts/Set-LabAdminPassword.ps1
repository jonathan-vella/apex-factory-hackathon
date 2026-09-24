<#
.SYNOPSIS
Sets the password of the local admin user, so an existing VM converges to the lab password.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, first on each datacenter VM. ARM sets
osProfile.adminPassword only when it creates a VM, so a re-deployment uses this script to bring an
existing VM to the deployed password. Setting the same password again changes nothing for the user.
.PARAMETER AdminUsername
The local admin user.
.PARAMETER AdminPassword
The password to set, passed as a protected run command parameter.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Set-LabAdminPassword.ps1 -AdminUsername labadmin -AdminPassword '<lab-password>'
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'AdminPassword',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams', '',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AdminUsername,
    [Parameter(Mandatory)]
    [string] $AdminPassword,
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Set-LabAdminPassword.log'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    Write-LabLog "Run ID: $RunId"
    # ADSI sets the password without putting it on a command line.
    $user = [ADSI]"WinNT://./$AdminUsername,user"
    $user.SetPassword($AdminPassword)
    $user.SetInfo()
    Write-LabLog "Set the password of $AdminUsername."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
