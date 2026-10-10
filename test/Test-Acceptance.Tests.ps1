#Requires -Version 7.4

<#
.SYNOPSIS
Runs acceptance-helper regression tests with an in-process fake Azure CLI and web client, never Azure.
.EXAMPLE
./test/Test-Acceptance.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$acceptance = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Test-Acceptance.ps1'
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$runner = @'
$ErrorActionPreference = 'Stop'
$base = '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-university-t/providers'
$types = [ordered]@{
    'st1' = 'Microsoft.Storage/storageAccounts'
    'sb1' = 'Microsoft.ServiceBus/namespaces'
    'kv1' = 'Microsoft.KeyVault/vaults'
    'acr1' = 'Microsoft.ContainerRegistry/registries'
    'mi1' = 'Microsoft.Sql/managedInstances'
    'app1' = 'Microsoft.Web/sites'
}
function global:az {
    $global:LASTEXITCODE = 0
    $command = $args -join ' '
    if ($scenario -eq 'cli-error') {
        $global:LASTEXITCODE = 1
        return 'Sensitive CLI error must not appear in output'
    }
    if ($command -like 'resource list*') {
        $items = foreach ($name in $types.Keys) {
            if ($scenario -eq 'no-webapp' -and $name -eq 'app1') { continue }
            @{ name = $name; type = $types[$name]; id = "$base/$($types[$name])/$name" }
        }
        return (ConvertTo-Json -Depth 5 -InputObject @($items))
    }
    if ($command -like 'webapp show*') {
        $https = $scenario -ne 'https-off'
        return (@{ httpsOnly = $https; defaultHostName = 'app1.example.test' } | ConvertTo-Json)
    }
    if ($command -like 'webapp config show*') {
        $tls = if ($scenario -eq 'tls11') { '1.1' } else { '1.2' }
        return (@{ minTlsVersion = $tls } | ConvertTo-Json)
    }
    if ($command -like 'network private-endpoint list*') {
        $items = foreach ($name in 'st1', 'sb1', 'kv1', 'acr1') {
            if ($scenario -eq 'no-pe' -and $name -eq 'kv1') { continue }
            $state = if ($scenario -eq 'pe-pending' -and $name -eq 'acr1') { 'Pending' } else { 'Approved' }
            @{
                name = "pe-$name"
                privateLinkServiceConnections = @(@{
                    privateLinkServiceId = "$base/$($types[$name])/$name"
                    privateLinkServiceConnectionState = @{ status = $state }
                })
                manualPrivateLinkServiceConnections = @()
            }
        }
        return (ConvertTo-Json -Depth 8 -InputObject @($items))
    }
    if ($command -like 'resource show*') {
        $id = $args[$args.IndexOf('--ids') + 1]
        if ($id -like '*managedInstances*') {
            $enabled = $scenario -eq 'mi-public'
            return (@{ properties = @{ publicDataEndpointEnabled = $enabled } } | ConvertTo-Json -Depth 4)
        }
        if ($scenario -eq 'missing-property' -and $id -like '*vaults*') { return (@{ properties = @{} } | ConvertTo-Json -Depth 4) }
        $access = if ($scenario -eq 'storage-public' -and $id -like '*storageAccounts*') { 'Enabled' } else { 'Disabled' }
        return (@{ properties = @{ publicNetworkAccess = $access } } | ConvertTo-Json -Depth 4)
    }
    throw "Unexpected Azure CLI command: $command"
}
function global:Invoke-WebRequest {
    # Like PowerShell 7: a 3xx with -MaximumRedirection 0 throws unless the error is silenced.
    [CmdletBinding()]
    param([string] $Uri, [int] $TimeoutSec, [switch] $SkipHttpErrorCheck, [int] $MaximumRedirection)
    if ($scenario -eq 'no-connection') { Write-Error 'The connection could not be established.'; return }
    if ($Uri -like 'http://*') {
        if ($scenario -eq 'no-redirect') { return [pscustomobject]@{ StatusCode = 200; Content = ''; Headers = @{} } }
        if ($PSBoundParameters['ErrorAction'] -ne 'SilentlyContinue') { throw [System.InvalidOperationException]::new('Operation is not valid due to the current state of the object.') }
        return [pscustomobject]@{ StatusCode = 301; Content = ''; Headers = @{ Location = @('https://app1.example.test/') } }
    }
    if ($scenario -eq 'page-500' -and $Uri -like '*/Courses') { return [pscustomobject]@{ StatusCode = 500; Content = 'error'; Headers = @{} } }
    $content = if ($scenario -eq 'no-rows' -and $Uri -like '*/Students') { '<table></table>' } else { '<table><tr><td>x</td></tr></table>' }
    [pscustomobject]@{ StatusCode = 200; Content = $content; Headers = @{} }
}
$parameters = @{ SubscriptionId = '11111111-1111-1111-1111-111111111111'; ResourceGroup = 'rg-university-t'; OutFile = $report }
if ($scenario -eq 'output-error') { $parameters.OutFile = Join-Path $report 'missing/report.json' }
& $acceptance @parameters
exit $LASTEXITCODE
'@

# Scenario, expected exit code, then the check that must carry the expected status.
$scenarios = @(
    @{ Name = 'healthy'; Exit = 0 }
    @{ Name = 'https-off'; Exit = 1; Check = 'HTTPS-only'; Status = 'FAIL' }
    @{ Name = 'tls11'; Exit = 1; Check = 'Minimum TLS 1.2'; Status = 'FAIL' }
    @{ Name = 'storage-public'; Exit = 1; Check = 'Public network access off'; Status = 'FAIL' }
    @{ Name = 'mi-public'; Exit = 1; Check = 'Public network access off'; Status = 'FAIL' }
    @{ Name = 'missing-property'; Exit = 1; Check = 'Public network access off'; Status = 'UNKNOWN' }
    @{ Name = 'no-pe'; Exit = 1; Check = 'Approved private endpoint'; Status = 'UNKNOWN' }
    @{ Name = 'pe-pending'; Exit = 1; Check = 'Approved private endpoint'; Status = 'FAIL' }
    @{ Name = 'page-500'; Exit = 1; Check = 'GET /Courses'; Status = 'FAIL' }
    @{ Name = 'no-rows'; Exit = 1; Check = 'GET /Students'; Status = 'FAIL' }
    @{ Name = 'no-redirect'; Exit = 1; Check = 'HTTP redirects to HTTPS'; Status = 'FAIL' }
    @{ Name = 'no-connection'; Exit = 1; Check = 'GET /'; Status = 'UNKNOWN' }
    @{ Name = 'no-webapp'; Exit = 1; Error = 'exactly one web app' }
    @{ Name = 'cli-error'; Exit = 1; Error = 'Azure CLI' }
    @{ Name = 'output-error'; Exit = 1; Error = "write the JSON" }
)
foreach ($scenarioCase in $scenarios) {
    $scenario = $scenarioCase.Name
    $report = [System.IO.Path]::GetTempFileName()
    try {
        $prefix = "`$scenario='$scenario'; `$report='$($report.Replace("'", "''"))'; `$acceptance='$($acceptance.Replace("'", "''"))';`n"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($prefix + $runner))
        $output = (& $pwsh -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne $scenarioCase.Exit) { throw "$scenario expected exit $($scenarioCase.Exit), got $exitCode`n$output" }
        if ($output -match '11111111-|Sensitive CLI error') { throw "$scenario leaked raw CLI details or the subscription ID." }
        if ($scenarioCase.Error) {
            if ($output -notmatch $scenarioCase.Error) { throw "$scenario didn't report '$($scenarioCase.Error)'.`n$output" }
            Write-Output "PASS: $scenario"
            continue
        }
        $data = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
        if (($data.Verdict -eq 'ACCEPT') -ne ($scenarioCase.Exit -eq 0)) { throw "$scenario JSON verdict mismatch." }
        if ($scenario -eq 'healthy') {
            if (@($data.Checks | Where-Object Status -NE 'PASS').Count -ne 0) { throw 'healthy has a non-PASS check.' }
            if (@($data.Checks).Count -ne 17) { throw "healthy expected 17 checks, got $(@($data.Checks).Count)." }
        }
        else {
            $match = @($data.Checks | Where-Object { $_.Check -eq $scenarioCase.Check -and $_.Status -eq $scenarioCase.Status })
            if ($match.Count -eq 0) { throw "$scenario has no $($scenarioCase.Status) for '$($scenarioCase.Check)'." }
        }
        Write-Output "PASS: $scenario"
    }
    finally {
        Remove-Item -LiteralPath $report -Force
    }
}
Write-Output "PASS: $($scenarios.Count) acceptance scenarios (no Azure calls)."
exit 0
