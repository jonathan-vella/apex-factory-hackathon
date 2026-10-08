#Requires -Version 7.0
<#
.SYNOPSIS
    azd postprovision hook: runs the post-deployment readiness tests and keeps later runs on the registry image.

.DESCRIPTION
    Wraps scripts/postdeploy-tests.ps1, reading the deployment outputs from the azd environment. On success it records
    CONTAINER_IMAGE (the registry copy) so a later `azd provision` does not revert the web app to the MCR placeholder.
    It then runs scripts/write-deployment-summary.ps1, which writes agent-output/university/06-deployment-summary.md
    from the live deployment record and test results (azd bypasses APEX Deploy, which would otherwise write this
    artifact) and tries to mark APEX Step 6 complete. That step is best-effort and never fails this hook.

.EXAMPLE
    azd provision   # azure.yaml runs this hook automatically
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$raw = & azd env get-values --output json
if ($LASTEXITCODE -ne 0) { throw 'azd env get-values failed.' }
$outputs = $raw | ConvertFrom-Json -Depth 8

$endpointNames = $outputs.privateEndpointNames
if ($endpointNames -is [string]) { $endpointNames = $endpointNames | ConvertFrom-Json }

$outcome = & (Join-Path $PSScriptRoot '..' 'postdeploy-tests.ps1') `
    -ResourceGroupName $outputs.resourceGroupName `
    -WebAppName $outputs.webAppName `
    -AcrName $outputs.acrName `
    -AcrLoginServer $outputs.acrLoginServer `
    -UamiClientId $outputs.uamiClientId `
    -PrivateEndpointNames @($endpointNames) `
    -SqlMiName $outputs.sqlMiName `
    -StorageAccountName $outputs.storageAccountName `
    -ServiceBusNamespaceName $outputs.serviceBusNamespaceName `
    -KeyVaultName $outputs.keyVaultName

& azd env set CONTAINER_IMAGE $outcome.ContainerImage | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'azd env set CONTAINER_IMAGE failed.' }

try {
    & (Join-Path $PSScriptRoot '..' 'write-deployment-summary.ps1') -Outcome $outcome
}
catch {
    Write-Warning "write-deployment-summary.ps1 failed; As-Built (agent 08) will need 06-deployment-summary.md written another way. Error: $_"
}
