#Requires -Version 7.4

<#
.SYNOPSIS
Shared assignment identity and ownership checks for the kit Reader grants. Dot-source this file.
.EXAMPLE
. (Join-Path $PSScriptRoot 'FactoryReaderAccess.ps1')
#>

$factoryReaderRole = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
$factoryReaderMarker = 'Created by Deploy-AlzLite.ps1 (Partner Modernization Factory): reader group'
$factoryLegacyReaderMarker = 'Created by Deploy-Vending.ps1 (Partner Modernization Factory)'

function Get-FactoryAssignmentName {
    param([string] $Scope, [string] $PrincipalId, [switch] $Legacy)
    if (-not $Legacy) {
        $Scope = $Scope.ToLowerInvariant()
        $PrincipalId = $PrincipalId.ToLowerInvariant()
    }
    # ARM guid() implements UUID v5 with this namespace and joins its inputs with hyphens.
    $namespace = [guid] '11fb06fb-712d-4ddd-98c7-e71bbd588830'
    $inputBytes = $namespace.ToByteArray($true) + [Text.Encoding]::UTF8.GetBytes("$Scope-$PrincipalId-$factoryReaderRole")
    $hash = [Security.Cryptography.SHA1]::HashData([byte[]] $inputBytes)
    $hash[6] = ($hash[6] -band 0x0f) -bor 0x50
    $hash[8] = ($hash[8] -band 0x3f) -bor 0x80
    [guid]::new([byte[]] $hash[0..15], $true).ToString()
}

function Test-FactoryReaderAssignment {
    param([Parameter(Mandatory)] $Assignment, [string] $Scope, [string] $GroupId, [switch] $Legacy)
    $properties = if ($Assignment.properties) { $Assignment.properties } else { $Assignment }
    if ($properties.scope -ne $Scope -or ($properties.roleDefinitionId -split '/')[-1] -ne $factoryReaderRole -or
        $properties.principalId -notmatch '^[0-9a-fA-F-]{36}$') { return $false }
    if ($Legacy) {
        if ($properties.description -cne $factoryLegacyReaderMarker) { return $false }
        foreach ($scopeCase in @($Scope, $properties.scope)) {
            if ($Assignment.name -eq (Get-FactoryAssignmentName -Scope $scopeCase -PrincipalId $properties.principalId -Legacy)) { return $true }
        }
        return $false
    }
    $properties.description -ceq $factoryReaderMarker -and $properties.principalType -eq 'Group' -and -not $properties.condition -and
        (-not $GroupId -or $properties.principalId -eq $GroupId) -and
        $Assignment.name -eq (Get-FactoryAssignmentName -Scope $Scope -PrincipalId $properties.principalId)
}

function Test-FactoryUserReader {
    param([string] $Scope, [guid] $PrincipalId, [string] $GroupId)
    $next = "https://management.azure.com$Scope/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01&`$filter=$([uri]::EscapeDataString("atScope() and assignedTo('$PrincipalId')"))"
    do {
        if ($next -notlike 'https://management.azure.com/*') { throw 'Unexpected Azure RBAC pagination link.' }
        $uriParts = $next -split '\?', 2
        $cliArgs = @('rest', '--method', 'get', '--uri', $uriParts[0])
        if ($uriParts.Count -gt 1 -and $uriParts[1]) {
            $queryArgs = @($uriParts[1] -split '&' | Where-Object { $_ } | ForEach-Object { [uri]::UnescapeDataString($_) })
            if ($queryArgs.Count) { $cliArgs += @('--uri-parameters') + $queryArgs }
        }
        $page = Invoke-AzureCli -Arguments $cliArgs
        foreach ($assignment in $page.value) {
            if (Test-FactoryReaderAssignment -Assignment $assignment -Scope $Scope -GroupId $GroupId) { return $true }
        }
        $next = $page.nextLink
    } while ($next)
    return $false
}
