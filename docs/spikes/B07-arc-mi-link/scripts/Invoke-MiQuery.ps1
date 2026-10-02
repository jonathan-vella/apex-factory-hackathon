<#
.SYNOPSIS
Runs T-SQL against the spike's SQL Managed Instance with an Entra access token, from vm-dev01.
.DESCRIPTION
Windows PowerShell 5.1, run as a VM run command on vm-dev01, which reaches the MI's private endpoint
over the peering. The run command runs as SYSTEM, which has no Entra identity, so the caller passes
its own token for https://database.windows.net/ as a protected parameter. The MI is Entra-only.

The query is base64-encoded UTF-8 so it survives the run command's quoting. Batches are split on
lines that hold only GO. Each result set is printed as JSON. Logs to
C:\LabTools\logs\Invoke-MiQuery.log, without the token.
.PARAMETER AccessToken
An access token for https://database.windows.net/, passed as a protected parameter.
.PARAMETER Server
The MI's host name.
.PARAMETER Database
The database to connect to.
.PARAMETER QueryBase64
The T-SQL, base64-encoded UTF-8.
.EXAMPLE
.\Invoke-MiQuery.ps1 -AccessToken '<token>' -Server '<mi-host-name>' -QueryBase64 'U0VMRUNUIDE='
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'AccessToken',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $AccessToken,
    [Parameter(Mandatory)]
    [string] $Server,
    [string] $Database = 'master',
    [Parameter(Mandatory)]
    [string] $QueryBase64
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Invoke-MiQuery.log'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    $query = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($QueryBase64))
    $batches = [regex]::Split($query, '(?im)^\s*GO\s*$') | Where-Object { $_.Trim() }
    $connection = New-Object System.Data.SqlClient.SqlConnection "Server=tcp:$Server,1433;Database=$Database;Encrypt=True;TrustServerCertificate=False;Connect Timeout=30;Application Name=LabTools"
    $connection.AccessToken = $AccessToken
    try {
        $connection.Open()
        Write-LabLog "Connected to $Server/$Database. Running $(@($batches).Count) batch(es)."
        foreach ($batch in $batches) {
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.CommandTimeout = 600
            $reader = $command.ExecuteReader()
            do {
                $rows = @()
                while ($reader.Read()) {
                    $row = [ordered]@{}
                    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $row[$reader.GetName($i)] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
                    }
                    $rows += New-Object PSObject -Property $row
                }
                if ($reader.FieldCount -gt 0) {
                    Write-Output (ConvertTo-Json -InputObject @($rows) -Depth 3 -Compress)
                }
            } while ($reader.NextResult())
            $reader.Dispose()
        }
    }
    finally {
        $connection.Dispose()
    }
    Write-LabLog 'Done.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
