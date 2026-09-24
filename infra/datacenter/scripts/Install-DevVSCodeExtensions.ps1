<#
.SYNOPSIS
Installs the lab's VS Code extensions for the signed-in user.
.DESCRIPTION
Runs at logon for every user on vm-dev01 (Windows PowerShell 5.1), from the scheduled task that
Register-DevFirstLogon.ps1 creates. VS Code extensions install per user, so a run command running as
SYSTEM can't install them. Extensions that are already installed are skipped, so later logons only
take a moment.
.EXAMPLE
.\Install-DevVSCodeExtensions.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-DevVSCodeExtensions.log'
$code = 'C:\Program Files\Microsoft VS Code\bin\code.cmd'
$extensions = @(
    'GitHub.copilot'
    'GitHub.copilot-chat'
    'vscjava.migrate-java-to-azure'
    'ms-dotnettools.csdevkit'
    'ms-mssql.mssql'
    'ms-vscode.powershell'
    'ms-azuretools.vscode-bicep'
)

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}' -f (Get-Date), $env:USERNAME, $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Invoke-Code {
    # Windows PowerShell 5.1 turns native stderr into terminating errors under 'Stop'.
    $ErrorActionPreference = 'Continue'
    & $code @args 2>&1 | ForEach-Object { "$_" }
}

try {
    if (-not (Test-Path $code)) {
        throw "VS Code not found at $code."
    }
    $installed = @(Invoke-Code --list-extensions | ForEach-Object { $_.ToLowerInvariant() })
    $missing = @($extensions | Where-Object { $installed -notcontains $_.ToLowerInvariant() })
    if ($missing.Count -eq 0) {
        Write-LabLog 'All lab extensions are installed.'
        exit 0
    }
    foreach ($extension in $missing) {
        Invoke-Code --install-extension $extension | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-LabLog "Failed to install $extension (exit $LASTEXITCODE)."
        }
        else {
            Write-LabLog "Installed $extension."
        }
    }
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
