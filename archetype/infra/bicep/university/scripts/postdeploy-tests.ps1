#Requires -Version 7.0
<#
.SYNOPSIS
    Post-deployment readiness tests for the university archetype.

.DESCRIPTION
    Runs PowerShell 7 and the Azure CLI only. Readiness is claimed only when every test passes. Failures return a
    non-zero exit through an exception and never widen access or fall back to another image source. The script
    imports the MCR placeholder image into the private registry, moves the web app to that registry copy through the
    user-assigned identity, and reports the resulting image reference in ContainerImage so the caller can persist it
    (for example with `azd env set CONTAINER_IMAGE`). DeployIfNotExists outcomes that are still being evaluated are
    reported as Pending, not Failed. Application telemetry is always reported as pending the app image.

.PARAMETER ResourceGroupName
    Archetype resource group (deployment output resourceGroupName).

.PARAMETER WebAppName
    Web app name (output webAppName).

.PARAMETER AcrName
    Container registry name (output acrName).

.PARAMETER AcrLoginServer
    Container registry login server (output acrLoginServer).

.PARAMETER UamiClientId
    Client ID of the web app identity (output uamiClientId).

.PARAMETER PrivateEndpointNames
    Private endpoint names (output privateEndpointNames).

.PARAMETER SqlMiName
    SQL managed instance name (output sqlMiName).

.PARAMETER StorageAccountName
    Storage account name (output storageAccountName).

.PARAMETER ServiceBusNamespaceName
    Service Bus namespace name (output serviceBusNamespaceName).

.PARAMETER KeyVaultName
    Key Vault name (output keyVaultName).

.PARAMETER WorkspaceName
    Central workspace name the diagnostic settings must target.

.PARAMETER DineTimeoutMinutes
    How long to wait for the asynchronous DeployIfNotExists remediations.

.EXAMPLE
    $outputs = azd env get-values --output json | ConvertFrom-Json
    ./postdeploy-tests.ps1 -ResourceGroupName $outputs.resourceGroupName -WebAppName $outputs.webAppName `
        -AcrName $outputs.acrName -AcrLoginServer $outputs.acrLoginServer -UamiClientId $outputs.uamiClientId `
        -PrivateEndpointNames $outputs.privateEndpointNames -SqlMiName $outputs.sqlMiName `
        -StorageAccountName $outputs.storageAccountName -ServiceBusNamespaceName $outputs.serviceBusNamespaceName `
        -KeyVaultName $outputs.keyVaultName

.OUTPUTS
    PSCustomObject with ContainerImage and Results (Name, Status, Detail).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ResourceGroupName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$WebAppName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AcrName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$AcrLoginServer,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$UamiClientId,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$PrivateEndpointNames,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SqlMiName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$StorageAccountName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ServiceBusNamespaceName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$KeyVaultName,
    [ValidateNotNullOrEmpty()][string]$WorkspaceName = 'log-management',
    [ValidateRange(1, 60)][int]$DineTimeoutMinutes = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$PlaceholderSource = 'mcr.microsoft.com/dotnet/samples:aspnetapp-10.0'
$RegistryImage = 'dotnet/samples:aspnetapp-10.0'
$script:Results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('Passed', 'Failed', 'Pending')][string]$Status,
        [Parameter(Mandatory)][string]$Detail
    )
    $script:Results.Add([PSCustomObject]@{ Name = $Name; Status = $Status; Detail = $Detail })
    Write-Host ("  [{0}] {1}: {2}" -f $Status.ToUpperInvariant(), $Name, $Detail)
}

function Invoke-AzJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments, [switch]$AllowFailure)
    $all = & az @Arguments --only-show-errors --output json 2>&1
    $exitCode = $LASTEXITCODE
    $errors = @($all | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n").Trim()
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        throw "az $($Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' ') failed: $($errors -join ' ')"
    }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text | ConvertFrom-Json -Depth 32
}

function Wait-Until {
    # Bounded polling: returns the first truthy value from the probe, or $null at the deadline.
    param(
        [Parameter(Mandatory)][scriptblock]$Probe,
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [int]$IntervalSeconds = 15
    )
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $value = & $Probe
        if ($value) { return $value }
        Start-Sleep -Seconds $IntervalSeconds
    } while ([DateTime]::UtcNow -lt $deadline)
    return $null
}

function Test-HttpOk {
    param([Parameter(Mandatory)][string]$Uri)
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Get -SkipHttpErrorCheck -TimeoutSec 30 -MaximumRedirection 0
        return ([int]$response.StatusCode -eq 200)
    }
    catch {
        return $false
    }
}

function Get-DiagnosticWorkspaceIds {
    param([Parameter(Mandatory)][string]$ResourceId)
    $settings = Invoke-AzJson -Arguments @('monitor', 'diagnostic-settings', 'list', '--resource', $ResourceId) -AllowFailure
    if ($null -eq $settings) { return @() }
    $items = if ($settings.PSObject.Properties['value']) { @($settings.value) } else { @($settings) }
    return @($items | ForEach-Object { $_.PSObject.Properties['workspaceId']?.Value } | Where-Object { $_ })
}

function Get-IpConfigurationFqdn {
    # FQDNs a private endpoint NIC IP configuration declares for itself (empty when the metadata is absent).
    param([Parameter(Mandatory)]$IpConfiguration)
    $properties = $IpConfiguration.PSObject.Properties['privateLinkConnectionProperties']?.Value
    if (-not $properties) { return @() }
    return @($properties.PSObject.Properties['fqdns']?.Value | Where-Object { $_ })
}

function Resolve-InKudu {
    # Resolves a name from the app's own network path through the Kudu command API (Entra token, no basic credentials).
    param(
        [Parameter(Mandatory)][string]$ScmHost,
        [Parameter(Mandatory)][string]$Token,
        [Parameter(Mandatory)][string]$Fqdn
    )
    foreach ($command in "nameresolver $Fqdn", "nslookup $Fqdn", "getent hosts $Fqdn") {
        try {
            $body = @{ command = $command; dir = '/' } | ConvertTo-Json -Compress
            $response = Invoke-RestMethod -Method Post -Uri "https://$ScmHost/api/command" -Headers @{ Authorization = "Bearer $Token" } -ContentType 'application/json' -Body $body -TimeoutSec 60
            $addresses = [regex]::Matches([string]$response.Output, '\b(?:\d{1,3}\.){3}\d{1,3}\b') | ForEach-Object { $_.Value }
            if ($addresses) { return @($addresses) }
        }
        catch {
            continue
        }
    }
    return @()
}

function Invoke-UniversityPostDeploy {
    [CmdletBinding()]
    param()

    Write-Host "Post-deployment tests for '$WebAppName'"
    $site = Invoke-AzJson -Arguments @('webapp', 'show', '--resource-group', $ResourceGroupName, '--name', $WebAppName)
    $siteId = $site.id
    $appHost = $site.defaultHostName
    $scmHost = @($site.hostNameSslStates | Where-Object { $_.hostType -eq 'Repository' } | ForEach-Object { $_.name }) | Select-Object -First 1

    # 1. MCR placeholder
    $placeholderUp = Wait-Until -TimeoutSeconds 600 -Probe { Test-HttpOk -Uri "https://$appHost/" }
    if ($placeholderUp) { Add-Result -Name 'MCR placeholder' -Status Passed -Detail 'the web app answered HTTP 200 on the MCR placeholder image' }
    else { Add-Result -Name 'MCR placeholder' -Status Failed -Detail 'no HTTP 200 from the placeholder image; check hub rule app-to-mcr and imagePullTraffic routing' }

    # 2. Routing
    $config = Invoke-AzJson -Arguments @('rest', '--method', 'get', '--url', "$siteId`?api-version=2025-03-01")
    $routing = $config.properties.PSObject.Properties['outboundVnetRouting']?.Value
    $routingOk = $routing -and $routing.allTraffic -eq $true -and $routing.imagePullTraffic -eq $true -and $config.properties.virtualNetworkSubnetId -match '/subnets/snet-app$'
    if ($routingOk) { Add-Result -Name 'Routing' -Status Passed -Detail 'allTraffic and imagePullTraffic are on and the app is integrated with snet-app' }
    else { Add-Result -Name 'Routing' -Status Failed -Detail 'outbound VNet routing or the snet-app integration is not as designed' }

    # 3. DeployIfNotExists private DNS: zone groups present and names resolve to the private endpoint addresses
    $targets = @(
        @{ Prefix = 'pe-acr-'; Fqdn = "$AcrName.azurecr.io" }
        @{ Prefix = 'pe-blob-'; Fqdn = "$StorageAccountName.blob.core.windows.net" }
        @{ Prefix = 'pe-sbns-'; Fqdn = "$ServiceBusNamespaceName.servicebus.windows.net" }
        @{ Prefix = 'pe-kv-'; Fqdn = "$KeyVaultName.vault.azure.net" }
    )
    $token = (& az account get-access-token --resource 'https://management.azure.com/' --query accessToken --output tsv).Trim()
    foreach ($target in $targets) {
        $endpointName = $PrivateEndpointNames | Where-Object { $_ -like "$($target.Prefix)*" } | Select-Object -First 1
        if (-not $endpointName) { Add-Result -Name "DNS $($target.Prefix.TrimEnd('-'))" -Status Failed -Detail 'private endpoint name missing from the deployment outputs'; continue }
        $zoneGroup = Wait-Until -TimeoutSeconds ($DineTimeoutMinutes * 60) -Probe {
            $groups = Invoke-AzJson -Arguments @('network', 'private-endpoint', 'dns-zone-group', 'list', '--resource-group', $ResourceGroupName, '--endpoint-name', $endpointName) -AllowFailure
            if (@($groups).Count -gt 0) { $groups } else { $null }
        }
        if (-not $zoneGroup) { Add-Result -Name "DNS $endpointName" -Status Failed -Detail 'no private DNS zone group appeared; the ALZ-lite DeployIfNotExists remediation did not run'; continue }
        $endpoint = Invoke-AzJson -Arguments @('network', 'private-endpoint', 'show', '--resource-group', $ResourceGroupName, '--name', $endpointName)
        $nic = Invoke-AzJson -Arguments @('network', 'nic', 'show', '--ids', $endpoint.networkInterfaces[0].id)
        # ACR private endpoints carry separate registry and regional data-endpoint IP configurations, so index zero is not
        # reliable. Match the configuration whose fqdns contain the target name. A first-IP fallback is allowed only for a
        # single-IP endpoint that declares no FQDN metadata at all; any other ambiguity fails readiness.
        $ipConfigurations = @($nic.ipConfigurations)
        $matchedConfigurations = @($ipConfigurations | Where-Object { (Get-IpConfigurationFqdn -IpConfiguration $_) -contains $target.Fqdn })
        $declaresFqdns = @($ipConfigurations | Where-Object { @(Get-IpConfigurationFqdn -IpConfiguration $_).Count -gt 0 }).Count -gt 0
        if ($matchedConfigurations.Count -eq 1) { $expected = $matchedConfigurations[0].privateIPAddress }
        elseif ($matchedConfigurations.Count -eq 0 -and $ipConfigurations.Count -eq 1 -and -not $declaresFqdns) { $expected = $ipConfigurations[0].privateIPAddress }
        else { Add-Result -Name "DNS $endpointName" -Status Failed -Detail "the endpoint NIC does not identify exactly one address for $($target.Fqdn) (ambiguous private endpoint evidence)"; continue }
        $resolved = Resolve-InKudu -ScmHost $scmHost -Token $token -Fqdn $target.Fqdn
        if ($resolved -contains $expected) { Add-Result -Name "DNS $endpointName" -Status Passed -Detail "$($target.Fqdn) resolves to the private endpoint address from the snet-app path" }
        else { Add-Result -Name "DNS $endpointName" -Status Failed -Detail "$($target.Fqdn) did not resolve to the private endpoint address from the snet-app path (hub DNS or zone link)" }
    }

    # 4. ACR import
    & az acr import --name $AcrName --source $PlaceholderSource --image $RegistryImage --force --only-show-errors --output none
    if ($LASTEXITCODE -eq 0) { Add-Result -Name 'ACR import' -Status Passed -Detail 'the placeholder image was imported through the trusted-services bypass' }
    else { Add-Result -Name 'ACR import' -Status Failed -Detail 'az acr import failed; check the deployer data-plane roles and the registry network bypass' }
    $containerImage = "$AcrLoginServer/$RegistryImage"

    # 5. Private pull through the user-assigned identity, kept on the registry copy
    $importPassed = @($script:Results | Where-Object { $_.Name -eq 'ACR import' -and $_.Status -eq 'Passed' }).Count -eq 1
    if ($importPassed) {
        # UAMI pull needs ARM audience tokens; fail before the image switch and never enable it from here.
        $armAuth = Invoke-AzJson -Arguments @('acr', 'config', 'authentication-as-arm', 'show', '--registry', $AcrName) -AllowFailure
        if (-not $armAuth -or $armAuth.status -ne 'enabled') {
            Add-Result -Name 'ACR ARM audience tokens' -Status Failed -Detail 'authentication-as-arm is not enabled on the registry, so the managed-identity pull cannot work; fix the registry setting and re-run'
            $importPassed = $false
        }
        else { Add-Result -Name 'ACR ARM audience tokens' -Status Passed -Detail 'authentication-as-arm is enabled on the registry' }
    }
    if ($importPassed) {
        # `linuxFxVersion` needs a literal '|' (DOCKER|image). On Windows, az.cmd runs through cmd.exe, which treats an
        # unescaped '|' in an argument as a pipe, so the web config is PATCHed through the ARM REST API with the
        # process-local token. A failed PATCH is recorded as a failed result and nothing is restarted.
        $switched = $false
        $switchFailure = $null
        try {
            $webConfigBody = @{ properties = @{ linuxFxVersion = "DOCKER|$containerImage"; acrUseManagedIdentityCreds = $true; acrUserManagedIdentityID = $UamiClientId } } | ConvertTo-Json -Compress
            Invoke-RestMethod -Uri "https://management.azure.com$siteId/config/web?api-version=2025-03-01" -Headers @{ Authorization = "Bearer $token" } -Method Patch -Body $webConfigBody -ContentType 'application/json' | Out-Null
            $switched = $true
        }
        catch {
            $switchFailure = "the web app config PATCH failed, so the image was not switched: $($_.Exception.Message)"
        }
        if ($switched) { & az webapp restart --resource-group $ResourceGroupName --name $WebAppName --only-show-errors --output none; $switched = $LASTEXITCODE -eq 0 }
        $pullUp = $switched -and (Wait-Until -TimeoutSeconds 600 -Probe { Test-HttpOk -Uri "https://$appHost/" })
        if ($pullUp) { Add-Result -Name 'ACR private pull' -Status Passed -Detail 'the web app runs the registry copy pulled over the private path with AcrPull' }
        elseif ($switchFailure) { Add-Result -Name 'ACR private pull' -Status Failed -Detail $switchFailure }
        else { Add-Result -Name 'ACR private pull' -Status Failed -Detail 'no HTTP 200 from the registry copy; check AcrPull, the pe-acr DNS result and imagePullTraffic' }
    }
    else {
        Add-Result -Name 'ACR private pull' -Status Failed -Detail 'skipped because the ACR import or the ARM audience token check did not pass'
    }

    # 6. Diagnostics readiness
    $workspaceSuffix = "/workspaces/$WorkspaceName"
    $dineTargets = [ordered]@{
        'web app'          = $siteId
        'container registry' = (Invoke-AzJson -Arguments @('acr', 'show', '--name', $AcrName)).id
        'Service Bus'      = (Invoke-AzJson -Arguments @('servicebus', 'namespace', 'show', '--resource-group', $ResourceGroupName, '--name', $ServiceBusNamespaceName)).id
        'Key Vault'        = (Invoke-AzJson -Arguments @('keyvault', 'show', '--name', $KeyVaultName)).id
        'SQL MI'           = (Invoke-AzJson -Arguments @('sql', 'mi', 'show', '--resource-group', $ResourceGroupName, '--name', $SqlMiName)).id
        'Application Insights' = (Invoke-AzJson -Arguments @('resource', 'list', '--resource-group', $ResourceGroupName, '--resource-type', 'Microsoft.Insights/components', '--query', '[0]')).id
    }
    $storageId = (Invoke-AzJson -Arguments @('storage', 'account', 'show', '--resource-group', $ResourceGroupName, '--name', $StorageAccountName)).id
    $dineTargets['blob service'] = "$storageId/blobServices/default"
    foreach ($label in $dineTargets.Keys) {
        $present = Wait-Until -TimeoutSeconds ($DineTimeoutMinutes * 60) -Probe {
            @(Get-DiagnosticWorkspaceIds -ResourceId $dineTargets[$label] | Where-Object { $_ -like "*$workspaceSuffix" }).Count -gt 0
        }
        if ($present) { Add-Result -Name "Diagnostics $label" -Status Passed -Detail "a setting targeting $WorkspaceName exists" }
        else { Add-Result -Name "Diagnostics $label" -Status Pending -Detail 'readiness pending: the DeployIfNotExists setting is not there yet (asynchronous evaluation)' }
    }
    $ownedTargets = @($PrivateEndpointNames | ForEach-Object { (Invoke-AzJson -Arguments @('network', 'private-endpoint', 'show', '--resource-group', $ResourceGroupName, '--name', $_)).id }) + @($storageId)
    $planId = (Invoke-AzJson -Arguments @('appservice', 'plan', 'list', '--resource-group', $ResourceGroupName, '--query', '[0]')).id
    foreach ($id in ($ownedTargets + $planId)) {
        $hasSetting = @(Get-DiagnosticWorkspaceIds -ResourceId $id | Where-Object { $_ -like "*$workspaceSuffix" }).Count -gt 0
        $label = ($id -split '/')[-1]
        if ($hasSetting) { Add-Result -Name "Metrics setting $label" -Status Passed -Detail 'the archetype metrics setting targets the central workspace' }
        else { Add-Result -Name "Metrics setting $label" -Status Failed -Detail 'the archetype metrics setting is missing' }
    }

    # 7. Telemetry is never claimed at deploy time
    Add-Result -Name 'Application telemetry' -Status Pending -Detail 'pending the app image (B06/B10); the placeholder sends no Application Insights telemetry'

    $failed = @($script:Results | Where-Object { $_.Status -eq 'Failed' })
    $outcome = [PSCustomObject]@{ ContainerImage = $containerImage; Results = @($script:Results) }
    if ($failed.Count -gt 0) {
        $record = [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new("Readiness not claimed: $($failed.Count) post-deployment test(s) failed ($(($failed | ForEach-Object { $_.Name }) -join ', '))."),
            'UniversityPostDeployFailed',
            [System.Management.Automation.ErrorCategory]::InvalidResult,
            $outcome)
        $PSCmdlet.ThrowTerminatingError($record)
    }
    Write-Host 'Post-deployment tests passed; telemetry and any pending diagnostics remain to be confirmed.'
    return $outcome
}

Invoke-UniversityPostDeploy
