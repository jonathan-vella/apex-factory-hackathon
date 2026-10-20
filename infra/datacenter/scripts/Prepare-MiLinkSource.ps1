#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
Prepares vm-app01's SQL Server and the ContosoUniversity database for the SQL Managed Instance link migration in C7. Safe to run again: it adds what's missing, resets the firewall rule's source address and takes a new full backup.
.DESCRIPTION
Run it on vm-app01 in a Bastion session, in Windows PowerShell 5.1, as an administrator (select Start, type powershell,
right-click Windows PowerShell and choose Run as administrator). It needs your own admin session: VM run commands stop working once
vm-app01 is Arc-enabled in C0, so there's no remote way to run it. The labadmin user is a SQL Server sysadmin.

It follows "Prepare environment for a Managed Instance link migration" (SQL Server migration in Azure Arc) and
logs each step with its time to C:\LabTools\logs\Prepare-MiLinkSource.log:

1. Windows Firewall: allows TCP 5022 inbound from the MI subnet only. Outbound is allowed by default.
2. Checks the instance: SQL Server 2022, availability groups on, trace flags 1800 and 9567 on,
   NT AUTHORITY\SYSTEM a sysadmin (the Arc extension uses it for cutover and cancel). The datacenter
   deployment sets these. If a check fails, the script stops and changes nothing else.
3. Creates a database master key in master, if there's none. Its password is random and isn't
   kept: the service master key opens it.
4. Imports the Azure root certificate authorities DigiCert Global Root G2 and Microsoft RSA Root
   Certificate Authority 2017 into master, as issuers for *.database.windows.net, so SQL Server
   trusts the MI's certificate.
5. Sets ContosoUniversity to the full recovery model.
6. Takes a full backup with checksum to F:\SQLBackup, which the link needs before seeding. It replaces the
   backup file of an earlier run.

The script only changes this VM. It never touches Azure, and the source database keeps working.

To check the script without running it (syntax, parameter check, help), run this from the repo root on any computer:
pwsh -NoProfile -File test/Test-MiLinkSource.Tests.ps1
.PARAMETER MiSubnetPrefix
The managed instance's subnet, snet-sqlmi in your spoke: 10.20.<n>.128/26, where <n> is your member index
(the memberIndex value in factory/.local/settings.json). For member 3, 10.20.3.128/26.
.EXAMPLE
.\Prepare-MiLinkSource.ps1 -MiSubnetPrefix 10.20.3.128/26
.EXAMPLE
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts/Prepare-MiLinkSource.ps1' -OutFile C:\LabTools\Prepare-MiLinkSource.ps1 -UseBasicParsing
C:\LabTools\Prepare-MiLinkSource.ps1 -MiSubnetPrefix 10.20.3.128/26
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({
        if ($_ -notmatch '^10\.20\.([1-9]|1[0-9]|20)\.128/26$') {
            throw "MiSubnetPrefix must be 10.20.<n>.128/26, where <n> (1 to 20) is your member index. Got '$_'."
        }
        $true
    })]
    [string] $MiSubnetPrefix
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Prepare-MiLinkSource.log'
$database = 'ContosoUniversity'
$certDir = 'C:\LabTools\arc\certs'
$rootCertificates = @(
    @{ Name = 'DigiCertPKI'; File = 'DigiCertGlobalRootG2.crt'; Url = 'https://cacerts.digicert.com/DigiCertGlobalRootG2.crt' }
    @{ Name = 'MicrosoftPKI'; File = 'MicrosoftRSARootCertificateAuthority2017.crt'; Url = 'https://www.microsoft.com/pkiops/certs/Microsoft%20RSA%20Root%20Certificate%20Authority%202017.crt' }
)

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Invoke-Sql {
    param(
        [string] $Query,
        [string] $Database = 'master',
        [int] $Timeout = 300
    )
    $connectionString = "Server=localhost;Database=$Database;Integrated Security=SSPI;Application Name=LabTools;Connect Timeout=15"
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = $Timeout
        $table = New-Object System.Data.DataTable
        $table.Load($command.ExecuteReader())
        Write-Output -InputObject $table -NoEnumerate
    }
    finally {
        $connection.Dispose()
    }
}

try {
    $ruleName = 'Allow MI link 5022 from the MI subnet'
    $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if (-not $rule) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5022 -RemoteAddress $MiSubnetPrefix -Profile Any | Out-Null
        Write-LabLog "Firewall: allowed TCP 5022 inbound from $MiSubnetPrefix."
    }
    else {
        $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $MiSubnetPrefix
        Write-LabLog "Firewall: TCP 5022 inbound from $MiSubnetPrefix already allowed."
    }

    $check = (Invoke-Sql -Query @"
DECLARE @tf TABLE (TraceFlag int, Status int, Global int, Session int);
INSERT @tf EXEC ('DBCC TRACESTATUS(1800, 9567) WITH NO_INFOMSGS');
SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(32)) AS Version,
       CAST(SERVERPROPERTY('IsHadrEnabled') AS int) AS Hadr,
       (SELECT COUNT(*) FROM @tf WHERE Global = 1) AS TraceFlags,
       IS_SRVROLEMEMBER('sysadmin', 'NT AUTHORITY\SYSTEM') AS SystemSysadmin;
"@).Rows[0]
    Write-LabLog "Instance: version $($check.Version), availability groups $($check.Hadr), trace flags on $($check.TraceFlags) of 2, SYSTEM sysadmin $($check.SystemSysadmin)."
    if (-not $check.Version.StartsWith('16.') -or $check.Hadr -ne 1 -or $check.TraceFlags -ne 2 -or $check.SystemSysadmin -ne 1) {
        throw 'The instance is not ready for MI link: it needs SQL Server 2022, availability groups on, trace flags 1800 and 9567 on, and SYSTEM as a sysadmin. Tell your coach.'
    }

    $hasKey = (Invoke-Sql -Query "SELECT COUNT(*) AS N FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##';").Rows[0].N
    if ($hasKey -eq 0) {
        $bytes = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $keyPassword = [Convert]::ToBase64String($bytes) + 'aA1!'
        Invoke-Sql -Query "CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'$keyPassword';" | Out-Null
        $keyPassword = $null
        Write-LabLog 'Created the database master key in master.'
    }
    else {
        Write-LabLog 'The database master key in master exists.'
    }

    New-Item -ItemType Directory -Force -Path $certDir | Out-Null
    foreach ($certificate in $rootCertificates) {
        $exists = (Invoke-Sql -Query "SELECT COUNT(*) AS N FROM sys.certificates WHERE name = N'$($certificate.Name)';").Rows[0].N
        if ($exists -eq 0) {
            $path = Join-Path $certDir $certificate.File
            Invoke-WebRequest -Uri $certificate.Url -OutFile $path -UseBasicParsing
            Invoke-Sql -Query @"
CREATE CERTIFICATE [$($certificate.Name)] FROM FILE = N'$path';
DECLARE @certId int = CERT_ID(N'$($certificate.Name)');
EXEC sp_certificate_add_issuer @certId, N'*.database.windows.net';
"@ | Out-Null
            Write-LabLog "Imported the root certificate $($certificate.Name) as an issuer for *.database.windows.net."
        }
        else {
            Write-LabLog "The root certificate $($certificate.Name) exists."
        }
    }

    $recovery = (Invoke-Sql -Query "SELECT recovery_model_desc AS R FROM sys.databases WHERE name = N'$database';").Rows[0].R
    if ($recovery -ne 'FULL') {
        Invoke-Sql -Query "ALTER DATABASE [$database] SET RECOVERY FULL;" | Out-Null
        Write-LabLog "Set $database to the full recovery model (was $recovery)."
    }
    else {
        Write-LabLog "$database uses the full recovery model."
    }

    $started = Get-Date
    $backup = "F:\SQLBackup\$database-milink.bak"
    Invoke-Sql -Timeout 3600 -Query "BACKUP DATABASE [$database] TO DISK = N'$backup' WITH INIT, CHECKSUM, COMPRESSION;" | Out-Null
    $size = (Invoke-Sql -Query "SELECT CAST(SUM(size) * 8 / 1024.0 AS decimal(10,1)) AS MB FROM sys.master_files WHERE database_id = DB_ID(N'$database') AND type = 0;").Rows[0].MB
    Write-LabLog ("Full backup with checksum to {0} in {1:N0} s. Data files: {2} MB; backup file: {3:N1} MB." -f $backup, ((Get-Date) - $started).TotalSeconds, $size, ((Get-Item $backup).Length / 1MB))
    Write-LabLog 'The source is ready for MI link.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
