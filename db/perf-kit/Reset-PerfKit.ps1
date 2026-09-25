#Requires -Version 7.4

<#
.SYNOPSIS
Puts the DB perf kit's planted issues back in ContosoUniversity and clears Query Store.
.DESCRIPTION
Runs on vm-dev01 against the source SQL Server or, after cutover, SQL MI. Runs the scripts in
db/perf-kit/sql in this order: 02-planted-objects.sql (the planted objects, and no index on
Enrollment.StudentID), 03-compatibility-level.sql (level 110), 04-query-store.sql (the Query Store
settings) and 90-reset.sql (drops every other added index and clears Query Store). Use it to re-run C9,
or to run C9 standalone. It doesn't touch the data. Needs only the SqlServer module, which it installs
for the current user if it's missing. The login needs db_owner: contosoapp on the source, the MI Entra
admin on MI.
.PARAMETER Server
The SQL Server to reset. Defaults to the source, 10.10.n.4. After cutover, the SQL MI host name.
.PARAMETER MemberIndex
The member index n, 1-20, which sets the default Server.
.PARAMETER Authentication
SqlPassword connects as contosoapp with the password from the datacenter secrets file (source only).
ActiveDirectoryDefault uses the signed-in Entra identity, which SQL MI needs after cutover.
.EXAMPLE
./db/perf-kit/Reset-PerfKit.ps1 -MemberIndex 1
.EXAMPLE
./db/perf-kit/Reset-PerfKit.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault
#>

[CmdletBinding()]
param(
    [string] $Server,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [ValidateSet('SqlPassword', 'ActiveDirectoryDefault')]
    [string] $Authentication = 'SqlPassword'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
if (-not $Server) {
    $Server = "10.10.$MemberIndex.4"
}
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'PerfKit.psm1') -Force
Import-PerfKitSqlServer
$connectionString = Get-PerfKitConnectionString -Server $Server -Authentication $Authentication

foreach ($script in '02-planted-objects.sql', '03-compatibility-level.sql', '04-query-store.sql', '90-reset.sql') {
    Write-Information "Running $script on $Server."
    Invoke-Sqlcmd -ConnectionString $connectionString -InputFile (Join-Path -Path $PSScriptRoot -ChildPath 'sql' -AdditionalChildPath $script) `
        -QueryTimeout 600 -Verbose:$true -ErrorAction Stop 4>&1 | ForEach-Object { Write-Information "  $_" }
}
Write-Information 'The planted issues are back and Query Store is empty. Run Start-Workload.ps1 to see them again.'
