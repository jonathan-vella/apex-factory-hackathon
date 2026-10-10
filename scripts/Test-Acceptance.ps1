#Requires -Version 7.4

<#
.SYNOPSIS
Collects read-only evidence for the C8 acceptance checks: page health, HTTPS-only, TLS and backend network settings.
.DESCRIPTION
Changes nothing. For the archetype's resource group it checks:
- the five app pages load over HTTPS, and the four list pages show table rows;
- plain HTTP is redirected to HTTPS;
- the web app is HTTPS-only with TLS 1.2 or later;
- Storage, Service Bus, Key Vault and Container Registry have public network access disabled, and an
  approved private endpoint, and SQL Managed Instance has its public data endpoint off.

It does not prove the uploads or the notification round-trip (do those in the browser), that the migrated
data is the right data (compare rows against the source), or the network path itself. A check that can't
be decided, for example a missing property or a resource the account can't read, is UNKNOWN, not PASS.
The exit code is 1 when any check is FAIL or UNKNOWN. The output names resources but never subscription IDs.
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER ResourceGroup
The archetype's resource group, for example rg-university-<suffix>.
.PARAMETER WebAppName
The web app's name. Optional when the resource group has exactly one web app.
.PARAMETER OutFile
Also save the checks and verdict as JSON.
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup 'rg-university-<suffix>' -OutFile (Join-Path '.local' 'acceptance.json')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroup,
    [string] $WebAppName,
    [string] $OutFile
)

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [string] $Area,
        [string] $Check,
        [string] $Resource,
        [ValidateSet('PASS', 'FAIL', 'UNKNOWN')]
        [string] $Status,
        [string] $Detail
    )
    $results.Add([pscustomobject]@{
        Area = $Area
        Check = $Check
        Resource = $Resource
        Status = $Status
        Detail = $Detail
    })
}

function Invoke-AzureCli {
    param([string[]] $Arguments)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $SubscriptionId --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 2) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE). Check sign-in, the resource group name and your access."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    try {
        return ConvertFrom-Json -InputObject $text -ErrorAction Stop
    }
    catch {
        throw 'Azure CLI returned an invalid JSON response.'
    }
}

function Get-WebResponse {
    param([string] $Uri)
    # PowerShell 7 throws on a 3xx when redirects are off, even with -SkipHttpErrorCheck, but still
    # returns the response when the error is silenced. No response at all (DNS, TLS, timeout) is an error.
    $response = Invoke-WebRequest -Uri $Uri -TimeoutSec 60 -SkipHttpErrorCheck -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable requestError
    if ($null -eq $response) {
        $reason = if ($requestError) { $requestError[0].Exception.Message } else { 'no response' }
        throw "No response from $Uri ($reason)."
    }
    return $response
}

function Invoke-Check {
    param([string] $Area, [string] $Check, [string] $Resource, [scriptblock] $Action)
    try {
        $outcome = & $Action
        Add-Result -Area $Area -Check $Check -Resource $Resource -Status $outcome.Status -Detail $outcome.Detail
    }
    catch {
        Add-Result -Area $Area -Check $Check -Resource $Resource -Status UNKNOWN -Detail $_.Exception.Message
    }
}

$inventory = @(Invoke-AzureCli @('resource', 'list', '--resource-group', $ResourceGroup))
if ($inventory.Count -eq 0) {
    throw "No resources found in '$ResourceGroup'. Check the resource group name and that C5 deployed."
}

# Web app.
$webApps = @($inventory | Where-Object { $_.type -eq 'Microsoft.Web/sites' })
if ($WebAppName) {
    $webApps = @($webApps | Where-Object { $_.name -eq $WebAppName })
}
if ($webApps.Count -ne 1) {
    throw "Expected exactly one web app in '$ResourceGroup', found $($webApps.Count). Pass -WebAppName."
}
$webApp = $webApps[0].name
$site = $null
Invoke-Check -Area 'Web app' -Check 'HTTPS-only' -Resource $webApp -Action {
    $script:site = Invoke-AzureCli @('webapp', 'show', '--resource-group', $ResourceGroup, '--name', $webApp)
    if ($null -eq $site.httpsOnly) { return @{ Status = 'UNKNOWN'; Detail = 'httpsOnly was not returned.' } }
    if ($site.httpsOnly -eq $true) { return @{ Status = 'PASS'; Detail = 'httpsOnly is true.' } }
    @{ Status = 'FAIL'; Detail = 'httpsOnly is false.' }
}
Invoke-Check -Area 'Web app' -Check 'Minimum TLS 1.2' -Resource $webApp -Action {
    $config = Invoke-AzureCli @('webapp', 'config', 'show', '--resource-group', $ResourceGroup, '--name', $webApp)
    $value = [string] $config.minTlsVersion
    $parsed = [version] '0.0'
    if (-not [version]::TryParse($value, [ref] $parsed)) { return @{ Status = 'UNKNOWN'; Detail = "minTlsVersion is '$value'." } }
    if ($parsed -ge [version] '1.2') { return @{ Status = 'PASS'; Detail = "minTlsVersion is $value." } }
    @{ Status = 'FAIL'; Detail = "minTlsVersion is $value; 1.2 or later is required." }
}

# Backends: public network access, then an approved private endpoint.
$endpoints = $null
try {
    $endpoints = @(Invoke-AzureCli @('network', 'private-endpoint', 'list', '--resource-group', $ResourceGroup))
}
catch {
    $endpointError = $_.Exception.Message
}
$backends = @(
    @{ Label = 'Storage'; Type = 'Microsoft.Storage/storageAccounts'; Property = 'publicNetworkAccess'; PrivateEndpoint = $true }
    @{ Label = 'Service Bus'; Type = 'Microsoft.ServiceBus/namespaces'; Property = 'publicNetworkAccess'; PrivateEndpoint = $true }
    @{ Label = 'Key Vault'; Type = 'Microsoft.KeyVault/vaults'; Property = 'publicNetworkAccess'; PrivateEndpoint = $true }
    @{ Label = 'Container Registry'; Type = 'Microsoft.ContainerRegistry/registries'; Property = 'publicNetworkAccess'; PrivateEndpoint = $true }
    @{ Label = 'SQL Managed Instance'; Type = 'Microsoft.Sql/managedInstances'; Property = 'publicDataEndpointEnabled'; PrivateEndpoint = $false }
)
foreach ($backend in $backends) {
    $found = @($inventory | Where-Object { $_.type -eq $backend.Type })
    if ($found.Count -eq 0) {
        Add-Result -Area $backend.Label -Check 'Resource found' -Resource $ResourceGroup -Status UNKNOWN -Detail "No $($backend.Type) in the resource group."
        continue
    }
    foreach ($resource in $found) {
        $property = $backend.Property
        $resourceId = $resource.id
        Invoke-Check -Area $backend.Label -Check 'Public network access off' -Resource $resource.name -Action {
            $detail = Invoke-AzureCli @('resource', 'show', '--ids', $resourceId)
            $value = $detail.properties.$property
            if ($null -eq $value -or "$value" -eq '') { return @{ Status = 'UNKNOWN'; Detail = "$property was not returned." } }
            $off = if ($property -eq 'publicDataEndpointEnabled') { $value -eq $false } else { "$value" -eq 'Disabled' }
            if ($off) { return @{ Status = 'PASS'; Detail = "$property is $value." } }
            @{ Status = 'FAIL'; Detail = "$property is $value." }
        }
        if ($backend.PrivateEndpoint) {
            Invoke-Check -Area $backend.Label -Check 'Approved private endpoint' -Resource $resource.name -Action {
                if ($null -eq $endpoints) { return @{ Status = 'UNKNOWN'; Detail = "Private endpoints couldn't be listed. $endpointError" } }
                $matching = foreach ($endpoint in $endpoints) {
                    foreach ($connection in @($endpoint.privateLinkServiceConnections) + @($endpoint.manualPrivateLinkServiceConnections)) {
                        if ($connection.privateLinkServiceId -eq $resourceId) {
                            [pscustomobject]@{ Name = $endpoint.name; State = $connection.privateLinkServiceConnectionState.status }
                        }
                    }
                }
                $matching = @($matching)
                if ($matching.Count -eq 0) { return @{ Status = 'UNKNOWN'; Detail = "No private endpoint in '$ResourceGroup' targets it. Check the portal: it may live in another resource group." } }
                $approved = @($matching | Where-Object State -EQ 'Approved')
                if ($approved.Count -gt 0) { return @{ Status = 'PASS'; Detail = "Approved: $($approved.Name -join ', ')." } }
                @{ Status = 'FAIL'; Detail = "Not approved: $(($matching | ForEach-Object { "$($_.Name) ($($_.State))" }) -join ', ')." }
            }
        }
    }
}

# App pages over HTTPS, and the HTTP redirect.
$hostName = $site.defaultHostName
if (-not $hostName) {
    Add-Result -Area 'App pages' -Check 'Host name' -Resource $webApp -Status UNKNOWN -Detail 'The web app has no default host name; pages were not tested.'
}
else {
    $pages = @(
        @{ Path = '/'; Rows = $false }
        @{ Path = '/Students'; Rows = $true }
        @{ Path = '/Courses'; Rows = $true }
        @{ Path = '/Instructors'; Rows = $true }
        @{ Path = '/Departments'; Rows = $true }
    )
    foreach ($page in $pages) {
        $uri = "https://$hostName$($page.Path)"
        $needRows = $page.Rows
        Invoke-Check -Area 'App pages' -Check "GET $($page.Path)" -Resource $webApp -Action {
            $response = Get-WebResponse -Uri $uri
            $code = [int] $response.StatusCode
            if ($code -ne 200) { return @{ Status = 'FAIL'; Detail = "HTTP $code." } }
            if ($needRows -and ([string] $response.Content) -notmatch '<td') { return @{ Status = 'FAIL'; Detail = 'HTTP 200, but the page has no table rows.' } }
            $suffix = if ($needRows) { ', with table rows (still compare the data with the source yourself)' } else { '' }
            @{ Status = 'PASS'; Detail = "HTTP 200$suffix." }
        }
    }
    Invoke-Check -Area 'App pages' -Check 'HTTP redirects to HTTPS' -Resource $webApp -Action {
        $response = Get-WebResponse -Uri "http://$hostName/"
        $code = [int] $response.StatusCode
        $location = [string] ($response.Headers['Location'] | Select-Object -First 1)
        if ($code -in 301, 302, 307, 308 -and $location -like 'https://*') { return @{ Status = 'PASS'; Detail = "HTTP $code to HTTPS." } }
        @{ Status = 'FAIL'; Detail = "HTTP $code, location '$location'." }
    }
}

$failures = @($results | Where-Object Status -EQ 'FAIL')
$unknowns = @($results | Where-Object Status -EQ 'UNKNOWN')
$verdict = if ($failures.Count -eq 0 -and $unknowns.Count -eq 0) { 'ACCEPT' } else { 'NOT ACCEPTED' }
$results | Format-Table Area, Check, Resource, Status, Detail -AutoSize -Wrap | Out-String -Width 200 | Write-Information -InformationAction Continue
Write-Information "$verdict`: $($failures.Count) failed, $($unknowns.Count) unknown, $(@($results | Where-Object Status -EQ 'PASS').Count) passed. Uploads, notifications and data correctness are not covered here." -InformationAction Continue

if ($OutFile) {
    try {
        [pscustomobject]@{
            Verdict = $verdict
            FailureCount = $failures.Count
            UnknownCount = $unknowns.Count
            Checks = $results
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutFile -Encoding utf8
    }
    catch {
        Write-Error "Couldn't write the JSON output: $($_.Exception.Message)" -ErrorAction Continue
        exit 1
    }
}
exit $(if ($verdict -eq 'ACCEPT') { 0 } else { 1 })
