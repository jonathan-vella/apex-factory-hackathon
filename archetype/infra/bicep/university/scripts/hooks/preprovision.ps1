#Requires -Version 7.0
<#
.SYNOPSIS
    azd preprovision hook: runs the read-only preflight and records the derived values in the azd environment.

.DESCRIPTION
    Wraps scripts/preflight.ps1. Nothing is created before every check passes. On success it sets AZURE_LOCATION,
    LOG_ANALYTICS_WORKSPACE_ID, SQLMI_DIRECTORY_IDENTITY_ID, DEPLOYER_OBJECT_ID and DEPLOYER_UPN in the azd environment, then prints the diagnosis
    command and cost note for a failed provisioning run (azd has no on-failure hook).

.EXAMPLE
    azd provision   # azure.yaml runs this hook automatically
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

foreach ($required in 'AZURE_TENANT_ID', 'AZURE_SUBSCRIPTION_ID', 'SUFFIX') {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($required))) {
        throw "Missing azd environment value $required. Run: azd env set $required <value>"
    }
}

$derived = & (Join-Path $PSScriptRoot '..' 'preflight.ps1')

$values = [ordered]@{
    AZURE_LOCATION            = $derived.Location
    LOG_ANALYTICS_WORKSPACE_ID = $derived.LogAnalyticsWorkspaceId
    SQLMI_DIRECTORY_IDENTITY_ID = $derived.SqlMiDirectoryIdentityId
    DEPLOYER_OBJECT_ID        = $derived.DeployerObjectId
    DEPLOYER_UPN              = $derived.DeployerUpn
}
foreach ($name in $values.Keys) {
    & azd env set $name $values[$name] | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "azd env set $name failed." }
}

Write-Host 'If provisioning fails, nothing is rolled back. Fix the cause and run azd provision again; the template is idempotent.'
Write-Host 'Diagnose: az deployment operation sub list --name <deployment> --query "[?properties.provisioningState==''Failed'']"'
Write-Host 'Cost while blocked: a partially created SQL managed instance bills about $0.68/hour (24x7, Azure Hybrid Benefit). Cleanup is always a manual decision.'
