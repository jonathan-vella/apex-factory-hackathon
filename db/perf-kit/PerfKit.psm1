#Requires -Version 7.4

<#
.SYNOPSIS
Shared helpers for the DB perf kit scripts: loads the SqlServer module and builds the connection string.
.DESCRIPTION
Imported by Start-Workload.ps1 and Reset-PerfKit.ps1. SqlPassword connects as contosoapp with the password
from the datacenter secrets file ($HOME/.apex-factory/<subscription-id>/datacenter.json), or the
documented lab password when the file isn't on this machine. ActiveDirectoryDefault connects as the
signed-in Entra identity, which SQL MI needs after cutover because it's Entra-only.
#>

$ErrorActionPreference = 'Stop'

function Import-PerfKitSqlServer {
    <#
    .SYNOPSIS
    Imports the SqlServer module, installing it for the current user first if it's missing.
    .EXAMPLE
    Import-PerfKitSqlServer
    #>
    [CmdletBinding()]
    param()
    if (-not (Get-Module -ListAvailable -Name SqlServer | Where-Object Version -GE '22.0')) {
        # Save into the first PSModulePath entry, the current user's module folder. Install-PSResource
        # resolves it from the Documents folder, which SYSTEM and some service accounts don't have.
        $userModules = ($env:PSModulePath -split [System.IO.Path]::PathSeparator)[0]
        Write-Information "Installing the SqlServer module for the current user, in $userModules."
        New-Item -ItemType Directory -Force -Path $userModules | Out-Null
        Save-PSResource -Name SqlServer -Path $userModules -TrustRepository -Quiet
    }
    Import-Module SqlServer -MinimumVersion 22.0 -DisableNameChecking
}

function Get-PerfKitConnectionString {
    <#
    .SYNOPSIS
    Returns the connection string to ContosoUniversity on the server, for the authentication method.
    .PARAMETER Server
    The source SQL Server (10.10.n.4) or the SQL MI host name.
    .PARAMETER Authentication
    SqlPassword (contosoapp, source only) or ActiveDirectoryDefault (Entra, MI after cutover).
    .EXAMPLE
    Get-PerfKitConnectionString -Server 10.10.1.4 -Authentication SqlPassword
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Server,
        [Parameter(Mandatory)]
        [ValidateSet('SqlPassword', 'ActiveDirectoryDefault')]
        [string] $Authentication
    )
    $builder = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $builder['Data Source'] = $Server
    $builder['Initial Catalog'] = 'ContosoUniversity'
    $builder['Application Name'] = 'PerfKit'
    $builder['Encrypt'] = $true
    $builder['Connect Timeout'] = 30
    if ($Authentication -eq 'SqlPassword') {
        $secretsFile = Get-ChildItem -Path (Join-Path -Path $HOME -ChildPath '.apex-factory') -Filter 'datacenter.json' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($secretsFile) {
            $secrets = Get-Content -Path $secretsFile.FullName -Raw | ConvertFrom-Json
            $login = $secrets.sqlAppLogin
            $password = $secrets.sqlAppPassword
        }
        else {
            # Fixed, documented lab password: see docs/backlog/README.md, Secrets.
            Write-Information 'No datacenter secrets file on this machine: using contosoapp with the documented lab password.'
            $login = 'contosoapp'
            $password = 'FactoryLab-2026-Pw'
        }
        $builder['User ID'] = $login
        $builder['Password'] = $password
        # The source SQL Server has a self-signed certificate.
        $builder['TrustServerCertificate'] = $true
    }
    else {
        $builder['Authentication'] = 'Active Directory Default'
    }
    return $builder.ConnectionString
}

Export-ModuleMember -Function Import-PerfKitSqlServer, Get-PerfKitConnectionString
