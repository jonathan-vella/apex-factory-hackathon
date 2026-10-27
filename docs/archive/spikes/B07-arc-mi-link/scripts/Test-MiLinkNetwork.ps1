<#
.SYNOPSIS
The SQL Server side of the MI link network test on vm-app01: a test endpoint for the MI's probe, and probes to the MI.
.DESCRIPTION
Windows PowerShell 5.1, run as SYSTEM through an Arc run command on vm-app01. Follows "Test network
connectivity" in "Prepare your environment for a link":

- Start: creates the test certificate and endpoint TEST_ENDPOINT on TCP 5022 (unless an endpoint
  already listens there), checks it locally, then probes the MI from vm-app01: TCP 5022 on the MI
  host name and the HADR port (11000-11999) on the MI node. This is what the page's SQL Agent job
  TestMILinkConnection runs (tnc), run here directly.
- Stop: drops TEST_ENDPOINT and TEST_CERT.

The MI side's probe (the NetHelper SQL Agent job on the MI) runs between Start and Stop.
Logs to C:\LabTools\logs\Test-MiLinkNetwork.log.
.PARAMETER Action
Start or Stop.
.PARAMETER MiHost
The MI's host name (the page's @serverName).
.PARAMETER MiNode
The MI's current primary node (the page's @node).
.PARAMETER MiHadrPort
The MI's HADR port (the page's @port).
.EXAMPLE
.\Test-MiLinkNetwork.ps1 -Action Start -MiHost '<mi-host-name>' -MiNode '<node>' -MiHadrPort 11002
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Start', 'Stop')]
    [string] $Action,
    [string] $MiHost,
    [string] $MiNode,
    [int] $MiHadrPort
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Test-MiLinkNetwork.log'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Invoke-Sql {
    param([string] $Query)
    $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=localhost;Database=master;Integrated Security=SSPI;Application Name=LabTools;Connect Timeout=15'
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $table = New-Object System.Data.DataTable
        $table.Load($command.ExecuteReader())
        Write-Output -InputObject $table -NoEnumerate
    }
    finally {
        $connection.Dispose()
    }
}

function Test-Port {
    param([string] $ComputerName, [int] $Port)
    $result = Test-NetConnection -ComputerName $ComputerName -Port $Port -WarningAction SilentlyContinue
    Write-LabLog ("vm-app01 -> {0}:{1} ({2}): TcpTestSucceeded {3}" -f $ComputerName, $Port, $result.RemoteAddress, $result.TcpTestSucceeded)
}

try {
    if ($Action -eq 'Start') {
        $endpoints = (Invoke-Sql -Query 'SELECT name FROM sys.tcp_endpoints WHERE port = 5022;').Rows
        if ($endpoints.Count -eq 0) {
            Invoke-Sql -Query @"
IF CERT_ID(N'TEST_CERT') IS NULL
    CREATE CERTIFICATE TEST_CERT WITH SUBJECT = N'Certificate for SQL Server', EXPIRY_DATE = N'3/30/2051';
CREATE ENDPOINT TEST_ENDPOINT STATE = STARTED AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATABASE_MIRRORING (ROLE = ALL, AUTHENTICATION = CERTIFICATE TEST_CERT, ENCRYPTION = REQUIRED ALGORITHM AES);
"@ | Out-Null
            Write-LabLog 'Created TEST_CERT and TEST_ENDPOINT on TCP 5022.'
        }
        else {
            Write-LabLog "An endpoint already listens on 5022: $($endpoints[0].name)."
        }
        Test-Port -ComputerName 'localhost' -Port 5022
        if ($MiHost) {
            Test-Port -ComputerName $MiHost -Port 5022
        }
        if ($MiNode -and $MiHadrPort) {
            Test-Port -ComputerName $MiNode -Port $MiHadrPort
        }
    }
    else {
        Invoke-Sql -Query @"
IF EXISTS (SELECT 1 FROM sys.endpoints WHERE name = N'TEST_ENDPOINT') DROP ENDPOINT TEST_ENDPOINT;
IF CERT_ID(N'TEST_CERT') IS NOT NULL DROP CERTIFICATE TEST_CERT;
"@ | Out-Null
        Write-LabLog 'Dropped TEST_ENDPOINT and TEST_CERT.'
    }
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
