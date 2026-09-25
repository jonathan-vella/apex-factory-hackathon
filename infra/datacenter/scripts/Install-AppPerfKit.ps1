<#
.SYNOPSIS
Installs the DB perf kit into ContosoUniversity on vm-app01: volume, planted issues, compatibility level and Query Store.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, after the legacy site's warm-up has created
and seeded the database. Downloads the numbered scripts from db/perf-kit/sql at the deployment's git ref
and runs them in order, batch by batch (split on GO), through SQL Server integrated authentication.
Every script is idempotent, so a re-run converges: seeding skips rows that exist, and the planted
objects, compatibility level and Query Store settings are put back.
.PARAMETER PerfKitBaseUrl
Base URL of db/perf-kit/sql at a git ref, as raw files.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Install-AppPerfKit.ps1 -PerfKitBaseUrl 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/db/perf-kit/sql'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $PerfKitBaseUrl,
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Install-AppPerfKit.log'
$downloadDir = 'C:\LabTools\perf-kit'
$scripts = '01-volume.sql', '02-planted-objects.sql', '03-compatibility-level.sql', '04-query-store.sql'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    Write-LabLog "Run ID: $RunId"
    New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
    foreach ($script in $scripts) {
        Invoke-WebRequest -Uri "$PerfKitBaseUrl/$script" -OutFile (Join-Path $downloadDir $script) -UseBasicParsing
    }
    Write-LabLog "Downloaded $($scripts.Count) scripts from $PerfKitBaseUrl."

    $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=localhost;Database=ContosoUniversity;Integrated Security=SSPI;Application Name=LabTools;Connect Timeout=30'
    # PRINT and RAISERROR ... WITH NOWAIT messages from the scripts are logged after each batch.
    $messages = New-Object System.Collections.Generic.List[string]
    $connection.add_InfoMessage({ $messages.Add($args[1].Message) })
    $connection.Open()
    try {
        foreach ($script in $scripts) {
            $started = Get-Date
            $text = Get-Content -Path (Join-Path $downloadDir $script) -Raw
            $batches = [regex]::Split($text, '(?im)^\s*GO\s*$') | Where-Object { $_.Trim() }
            foreach ($batch in $batches) {
                $command = $connection.CreateCommand()
                $command.CommandText = $batch
                $command.CommandTimeout = 3600
                try {
                    [void] $command.ExecuteNonQuery()
                }
                finally {
                    $command.Dispose()
                    foreach ($message in $messages) { Write-LabLog "  $message" }
                    $messages.Clear()
                }
            }
            Write-LabLog ('{0} finished in {1:n0} s.' -f $script, ((Get-Date) - $started).TotalSeconds)
        }
    }
    finally {
        $connection.Dispose()
    }
    Write-LabLog 'The DB perf kit is installed.'
    exit 0
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
