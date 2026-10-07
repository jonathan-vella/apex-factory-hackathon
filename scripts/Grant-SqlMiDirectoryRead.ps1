#Requires -Version 7.4

<#
.SYNOPSIS
Grants id-sqlmi-directory the Microsoft Graph read permissions SQL Managed Instance needs to add Entra users.
.DESCRIPTION
ALZ-lite creates the team's user-assigned managed identity id-sqlmi-directory in rg-management of the shared
services subscription. Every member's SQL Managed Instance (the CoE archetype) uses it as its primary identity,
so CREATE USER ... FROM EXTERNAL PROVIDER can look up Microsoft Entra principals, for example the web app's
identity in C7. This script gives it the three Microsoft Graph application permissions Microsoft Learn lists
for that: User.Read.All, GroupMember.Read.All and Application.Read.All.
Run it once per team, after scripts/Deploy-AlzLite.ps1, signed in (az login) as a Privileged Role
Administrator or Global Administrator of the tenant. It's event prep, not an attendee step. A re-run
skips permissions that are already granted. Use -WhatIf to see what it would grant.
Removing rg-management (teardown) deletes the identity and its permissions with it.
.PARAMETER SharedSubscriptionId
The team's shared services subscription.
.PARAMETER ResourceGroup
The resource group that holds the identity.
.PARAMETER IdentityName
The identity's name.
.EXAMPLE
./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId,
    [string] $ResourceGroup = 'rg-management',
    [string] $IdentityName = 'id-sqlmi-directory'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$graphAppId = '00000003-0000-0000-c000-000000000000'
$permissions = @('User.Read.All', 'GroupMember.Read.All', 'Application.Read.All')

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

$identity = Invoke-AzureCli -Arguments @('identity', 'show', '--subscription', $SharedSubscriptionId,
    '--resource-group', $ResourceGroup, '--name', $IdentityName)
$principalId = $identity.principalId
Write-Information "Identity: $IdentityName in $ResourceGroup (shared services subscription)."

$graph = (Invoke-AzureCli -Arguments @('rest', '--method', 'GET', '--url', 'https://graph.microsoft.com/v1.0/servicePrincipals',
        '--uri-parameters', "`$filter=appId eq '$graphAppId'", '$select=id,appRoles')).value | Select-Object -First 1
$granted = @((Invoke-AzureCli -Arguments @('rest', '--method', 'GET', '--url',
            "https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments")).value |
    Where-Object { $_.resourceId -eq $graph.id } | ForEach-Object { $_.appRoleId })

foreach ($permission in $permissions) {
    $role = $graph.appRoles | Where-Object { $_.value -eq $permission -and $_.allowedMemberTypes -contains 'Application' }
    if (-not $role) {
        throw "Microsoft Graph has no application permission named $permission."
    }
    if ($granted -contains $role.id) {
        Write-Information "  $permission already granted."
        continue
    }
    if (-not $PSCmdlet.ShouldProcess($IdentityName, "Grant Microsoft Graph $permission")) {
        continue
    }
    $body = @{ principalId = $principalId; resourceId = $graph.id; appRoleId = $role.id } | ConvertTo-Json -Compress
    $bodyFile = Join-Path ([System.IO.Path]::GetTempPath()) "graph-grant-$([guid]::NewGuid()).json"
    Set-Content -Path $bodyFile -Value $body -Encoding utf8NoBOM -WhatIf:$false
    try {
        $null = Invoke-AzureCli -Arguments @('rest', '--method', 'POST', '--url',
            "https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments",
            '--headers', 'Content-Type=application/json', '--body', "@$bodyFile")
    }
    catch {
        throw @"
Granting $permission failed. Granting Microsoft Graph application permissions needs the Privileged Role
Administrator or Global Administrator role in the tenant. Sign in with such an account (az login) and re-run.
$($_.Exception.Message)
"@
    }
    finally {
        Remove-Item -Path $bodyFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
    }
    Write-Information "  $permission granted."
}

if (-not $WhatIfPreference) {
    Write-Information @"

$IdentityName can read Microsoft Entra users, groups and service principals. Every member's SQL Managed
Instance uses it as its primary identity, so C7 can create the web app's contained database user.
"@
}
