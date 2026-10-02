<#
.SYNOPSIS
Prepares vm-app01's SQL Server and ContosoUniversity for an MI link migration. Idempotent.
.DESCRIPTION
Windows PowerShell 5.1, run as SYSTEM (a sysadmin on vm-app01) through an Arc run command, which
docs/spikes/B07-arc-mi-link/infra/arc-source-prep.bicep deploys. VM run commands no longer work
once vm-app01 is Arc-enabled. It follows "Prepare environment for a Managed Instance link
migration" (SQL Server migration in Azure Arc) and logs each step with its time to
C:\LabTools\logs\Prepare-MiLinkSource.log:

1. Windows Firewall: allows TCP 5022 inbound from the MI subnet only. Outbound is allowed by default.
2. Checks the instance: SQL Server 2022, availability groups on, trace flags 1800 and 9567 on,
   NT AUTHORITY\SYSTEM a sysadmin (the Arc extension uses it for cutover and cancel).
3. Creates a database master key in master, if there's none. Its password is random and isn't
   kept: the service master key opens it.
4. Imports the Azure root certificate authorities DigiCert Global Root G2 and Microsoft RSA Root
   Certificate Authority 2017 into master, as issuers for *.database.windows.net, so SQL Server
   trusts the MI's certificate.
5. Sets ContosoUniversity to the full recovery model.
6. Takes a full backup with checksum to F:\SQLBackup, which the link needs before seeding.
.PARAMETER MiSubnetPrefix
The MI subnet, for example 10.20.1.128/26.
.EXAMPLE
.\Prepare-MiLinkSource.ps1 -MiSubnetPrefix 10.20.1.128/26
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
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
        throw 'The instance is not ready for MI link. Re-run scripts/Deploy-Datacenter.ps1 before Arc onboarding.'
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
