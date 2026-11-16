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
The SQL Server to reset. Defaults to the source vm-app01 IP derived from -MemberIndex. After cutover, the SQL MI host name.
.PARAMETER MemberIndex
The member index n (1 or greater), which sets the default Server.
.PARAMETER Authentication
SqlPassword connects as contosoapp (source only), with -SqlPassword, else the password in the kit folder's .local/<subscription-id>/datacenter.json, else the documented lab password.
ActiveDirectoryDefault uses the signed-in Entra identity, which SQL MI needs after cutover.
ActiveDirectoryInteractive signs in as you in a browser. Use it on vm-dev01: it doesn't depend on az login
or on what the VM itself holds.
.PARAMETER SqlPassword
The contosoapp password, if you deployed the datacenter with -SqlAppPassword. The VM's clone of the kit has no
.local folder, so it can't find the password itself.
.EXAMPLE
./db/perf-kit/Reset-PerfKit.ps1 -MemberIndex 1
.EXAMPLE
./db/perf-kit/Reset-PerfKit.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryInteractive
#>

[CmdletBinding()]
param(
    [string] $Server,
    [ValidateRange(1, [int]::MaxValue)]
    [int] $MemberIndex = 1,
    [ValidateSet('SqlPassword', 'ActiveDirectoryDefault', 'ActiveDirectoryInteractive')]
    [string] $Authentication = 'SqlPassword',
    [securestring] $SqlPassword
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Get-MemberNetworkPlan {
    param([int] $MemberIndex)
    $block = [int][Math]::Floor($MemberIndex / 256)
    if ($block -gt 64) {
        throw "MemberIndex $MemberIndex exceeds the IPv4 address pool capacity."
    }
    $dcOct2 = if ($block -eq 0) { 10 } else { 127 + $block }
    $spokeOct2 = if ($block -eq 0) { 20 } else { 191 + $block }
    $oct3 = $MemberIndex % 256
    return [pscustomobject]@{
        DcSecondOctet    = $dcOct2
        SpokeSecondOctet = $spokeOct2
        ThirdOctet       = $oct3
        DatacenterPrefix = "10.$dcOct2.$oct3.0/24"
        SpokePrefix      = "10.$spokeOct2.$oct3.0/24"
        AppVmIp          = "10.$dcOct2.$oct3.4"
        DevVmIp          = "10.$dcOct2.$oct3.5"
        AppSubnet        = "10.$spokeOct2.$oct3.0/26"
        PeSubnet         = "10.$spokeOct2.$oct3.64/26"
        MiSubnet         = "10.$spokeOct2.$oct3.128/26"
        SpokeUpperHalf   = "10.$spokeOct2.$oct3.128/25"
    }
}

$networkPlan = Get-MemberNetworkPlan -MemberIndex $MemberIndex
if (-not $Server) {
    $Server = $networkPlan.AppVmIp
}
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'PerfKit.psm1') -Force
Import-PerfKitSqlServer
$connectionString = Get-PerfKitConnectionString -Server $Server -Authentication $Authentication -SqlPassword $SqlPassword

foreach ($script in '02-planted-objects.sql', '03-compatibility-level.sql', '04-query-store.sql', '90-reset.sql') {
    Write-Information "Running $script on $Server."
    Invoke-Sqlcmd -ConnectionString $connectionString -InputFile (Join-Path -Path $PSScriptRoot -ChildPath 'sql' -AdditionalChildPath $script) `
        -QueryTimeout 600 -Verbose:$true -ErrorAction Stop 4>&1 | ForEach-Object { Write-Information "  $_" }
}
Write-Information 'The planted issues are back and Query Store is empty. Run Start-Workload.ps1 to see them again.'
