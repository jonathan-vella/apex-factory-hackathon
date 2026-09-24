<#
.SYNOPSIS
Creates the empty ContosoUniversity database on F: and the contosoapp SQL login as its db_owner.
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1) as SYSTEM, after Set-AppSqlServer.ps1. The app
creates the schema and seeds the data on its first request. Re-runs change nothing unless the
password differs.
.PARAMETER SqlAppPassword
Password of the contosoapp login, passed as a protected run command parameter.
.EXAMPLE
.\New-AppDatabase.ps1 -SqlAppPassword '<generated-password>'
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'SqlAppPassword',
    Justification = 'Run commands pass protected parameters as plain strings.')]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SqlAppPassword
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'New-AppDatabase.log'
$database = 'ContosoUniversity'
$login = 'contosoapp'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

function Invoke-Sql {
    param(
        [string] $Query,
        [string] $Database = 'master'
    )
    $connectionString = "Server=localhost;Database=$Database;Integrated Security=SSPI;Application Name=LabTools;Connect Timeout=15"
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $command.CommandTimeout = 300
        $table = New-Object System.Data.DataTable
        $table.Load($command.ExecuteReader())
        Write-Output -InputObject $table -NoEnumerate
    }
    finally {
        $connection.Dispose()
    }
}

try {
    $escapedPassword = $SqlAppPassword.Replace("'", "''")

    $result = Invoke-Sql -Query @"
IF DB_ID(N'$database') IS NULL
BEGIN
    CREATE DATABASE [$database]
        ON PRIMARY (NAME = N'$database', FILENAME = N'F:\SQLData\$database.mdf')
        LOG ON (NAME = N'${database}_log', FILENAME = N'F:\SQLLog\${database}_log.ldf');
    SELECT 'created' AS Result;
END
ELSE
    SELECT 'exists' AS Result;
"@
    Write-LabLog "Database ${database}: $($result.Rows[0].Result)."

    $result = Invoke-Sql -Query @"
IF SUSER_ID(N'$login') IS NULL
BEGIN
    CREATE LOGIN [$login] WITH PASSWORD = N'$escapedPassword', DEFAULT_DATABASE = [$database], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;
    SELECT 'created' AS Result;
END
ELSE IF PWDCOMPARE(N'$escapedPassword', (SELECT password_hash FROM sys.sql_logins WHERE name = N'$login')) = 0
BEGIN
    ALTER LOGIN [$login] WITH PASSWORD = N'$escapedPassword';
    SELECT 'password updated' AS Result;
END
ELSE
    SELECT 'exists' AS Result;
"@
    Write-LabLog "Login ${login}: $($result.Rows[0].Result)."

    Invoke-Sql -Database $database -Query @"
IF USER_ID(N'$login') IS NULL CREATE USER [$login] FOR LOGIN [$login];
IF IS_ROLEMEMBER(N'db_owner', N'$login') = 0 ALTER ROLE [db_owner] ADD MEMBER [$login];
"@ | Out-Null
    Write-LabLog "User $login is db_owner of $database."
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
