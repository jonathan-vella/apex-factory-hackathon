#Requires -Version 7.4

<#
.SYNOPSIS
Checks an attendee's Azure prerequisites without deploying resources.
.DESCRIPTION
Reports automated and manual C0 checks. Only -Fix changes Azure: it registers
missing resource providers and the Microsoft.Network public IP feature, and polls for up to 15 minutes
per subscription and step, so run it once and wait.
-Fix does nothing while an earlier check (tools, sign-in, role, region) has a FAIL or the VM size is
restricted; unregistered providers don't block it. The role check needs an unconditional Owner
assignment: Contributor isn't accepted. Warnings and manual checks do not block GO, so read every WARN
row: GO means no FAIL, not no WARN. The MANUAL rows are MFA, GitHub Copilot, GitHub repositories, APEX and
Azure Hybrid Benefit. Quota is deliberately not checked.
The kit uses non-zonal VMs. germanywestcentral is the documented fallback region.
.PARAMETER WorkloadSubscriptionId
The member's workload subscription.
.PARAMETER SharedSubscriptionId
The team's shared services subscription. Only the platform lead passes this: it adds the shared
subscription's tenant, Owner and resource provider checks, and with -Fix registers its providers.
.PARAMETER Location
The target Azure region, defaulting to swedencentral.
.PARAMETER ParentManagementGroupId
The management group the kit deploys under, instead of Tenant Root. The management-group check then looks for rights there.
.PARAMETER Fix
Register missing providers and the public IP feature after the prerequisite checks pass.
.PARAMETER OutFile
Also save the checks, verdict and failure count as JSON.
.EXAMPLE
./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId '<workload-subscription-id>'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -Fix -OutFile (Join-Path '.local' 'preflight.json')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $WorkloadSubscriptionId,
    [string] $SharedSubscriptionId,
    [string] $Location = 'swedencentral',
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [switch] $Fix,
    [string] $OutFile
)

$ErrorActionPreference = 'Stop'
$targetLocation = $Location
$registerMissing = $Fix.IsPresent
$results = [System.Collections.Generic.List[object]]::new()
$subscriptions = [System.Collections.Generic.List[object]]::new()
$providers = @(
    'Microsoft.Compute', 'Microsoft.Network', 'Microsoft.Storage', 'Microsoft.Sql',
    'Microsoft.Web', 'Microsoft.ContainerRegistry', 'Microsoft.ServiceBus',
    'Microsoft.KeyVault', 'Microsoft.ManagedIdentity', 'Microsoft.Insights',
    'Microsoft.OperationalInsights', 'Microsoft.OperationsManagement',
    'Microsoft.HybridCompute', 'Microsoft.GuestConfiguration', 'Microsoft.AzureArcData',
    'Microsoft.PolicyInsights', 'Microsoft.Security', 'Microsoft.Management'
)

function Add-Result {
    param(
        [string] $Check,
        [ValidateSet('PASS', 'FAIL', 'WARN', 'MANUAL')]
        [string] $Status,
        [string] $Reason,
        [string] $Remedy = ''
    )
    $results.Add([pscustomobject]@{
        Check = $Check
        Status = $Status
        Reason = $Reason
        Fix = $Remedy
    })
}

function Invoke-AzureCli {
    param([string[]] $Arguments, [switch] $AsText, [switch] $AllowEmpty)
    # Capture native stderr rather than letting the CLI print tenant/subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 2) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE). Check sign-in, access and arguments."
    }
    $text = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"
    if ($AsText) {
        return $text
    }
    if ([string]::IsNullOrWhiteSpace($text)) {
        if ($AllowEmpty) { return }
        throw 'Azure CLI returned an empty response.'
    }
    try {
        return ConvertFrom-Json -InputObject $text -ErrorAction Stop
    }
    catch {
        throw 'Azure CLI returned an invalid JSON response.'
    }
}

function Invoke-Check {
    param([string] $Name, [scriptblock] $Action, [string] $Remedy)
    try {
        & $Action
    }
    catch {
        Add-Result -Check $Name -Status FAIL -Reason $_.Exception.Message -Remedy $Remedy
    }
}

Add-Result -Check 'PowerShell' -Status PASS -Reason "PowerShell $($PSVersionTable.PSVersion); requires 7.4 or later."
$account = $null
Invoke-Check -Name 'Azure CLI' -Action {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI is not installed.'
    }
    $version = (Invoke-AzureCli @('version')).'azure-cli'
    if ([version] $version -lt [version] '2.70') {
        throw 'Azure CLI is older than 2.70.'
    }
    $script:account = Invoke-AzureCli @('account', 'show')
    # account show is cached; a token request also detects an expired login.
    $null = Invoke-AzureCli @('account', 'get-access-token')
    Add-Result -Check 'Azure CLI' -Status PASS -Reason "Azure CLI $version; signed in."
} -Remedy 'Install Azure CLI 2.70 or later, then run az login in the intended tenant.'

Invoke-Check -Name 'Bicep' -Action {
    $text = Invoke-AzureCli @('bicep', 'version') -AsText
    if ($text -notmatch 'Bicep CLI version (\d+\.\d+\.\d+)') {
        throw 'Cannot determine the Bicep CLI version.'
    }
    $version = $Matches[1]
    if ([version] $version -lt [version] '0.30') {
        throw 'Bicep CLI is older than 0.30.'
    }
    Add-Result -Check 'Bicep' -Status PASS -Reason "Bicep $version; requires 0.30 or later."
} -Remedy 'Run az bicep install or az bicep upgrade to install Bicep 0.30 or later.'

$targets = @([pscustomobject]@{ Label = 'workload'; Id = $WorkloadSubscriptionId })
if ($SharedSubscriptionId) {
    $targets += [pscustomobject]@{ Label = 'shared'; Id = $SharedSubscriptionId }
    if ($SharedSubscriptionId -eq $WorkloadSubscriptionId) {
        Add-Result -Check 'Subscriptions' -Status FAIL -Reason 'Workload and shared subscriptions must differ.' -Remedy 'Pass two different subscriptions.'
    }
}
foreach ($target in $targets) {
    Invoke-Check -Name "Tenant: $($target.Label)" -Action {
        $parsedId = [guid]::Empty
        if (-not [guid]::TryParse($target.Id, [ref] $parsedId)) {
            throw 'The subscription ID is not a valid GUID.'
        }
        if (-not $account) {
            throw 'The signed-in tenant could not be determined.'
        }
        $subscription = Invoke-AzureCli @('account', 'show', '--subscription', $target.Id)
        if ($subscription.tenantId -ne $account.tenantId) {
            throw 'The subscription belongs to a different tenant than the signed-in account.'
        }
        if ($subscription.state -ne 'Enabled') {
            throw 'The subscription is not enabled.'
        }
        $subscriptions.Add($target)
        Add-Result -Check "Tenant: $($target.Label)" -Status PASS -Reason 'Subscription exists, is enabled and is in the signed-in tenant.'
    } -Remedy 'Check the subscription ID and access; run az login in its tenant. The subscription may not exist or may be inaccessible.'
}

$userId = $null
$callerIsUser = $true
function Get-CallerAssignment {
    param([string] $Scope, [string] $Subscription)
    if ($callerIsUser) {
        return @(Invoke-AzureCli @(
            'role', 'assignment', 'list', '--assignee', $userId, '--scope', $Scope, '--subscription', $Subscription,
            '--include-inherited', '--include-groups'
        ))
    }
    # A service principal or managed identity has no group lookup; list the scope and keep its own assignments.
    return @(Invoke-AzureCli @(
        'role', 'assignment', 'list', '--scope', $Scope, '--subscription', $Subscription, '--include-inherited'
    ) | Where-Object { $_.principalId -eq $userId })
}

if ($subscriptions.Count -gt 0) {
    Invoke-Check -Name 'Account identity' -Action {
        if ($account.user.type -ne 'servicePrincipal') {
            $script:userId = (Invoke-AzureCli @('ad', 'signed-in-user', 'show')).id
        }
        else {
            # A pipeline identity: take its object ID from the ARM token, so no Microsoft Graph call is needed.
            $script:callerIsUser = $false
            $token = Invoke-AzureCli @('account', 'get-access-token', '--resource', 'https://management.azure.com/', '--query', 'accessToken')
            $payload = $token.Split('.')[1].Replace('-', '+').Replace('_', '/')
            $payload += '=' * ((4 - $payload.Length % 4) % 4)
            $script:userId = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json).oid
        }
        if (-not $userId) { throw 'Cannot resolve the signed-in identity.' }
        if ($callerIsUser) {
            Add-Result -Check 'Account identity' -Status PASS -Reason 'Signed-in user resolved for group-aware role checks.'
        }
        else {
            Add-Result -Check 'Account identity' -Status PASS -Reason 'Pipeline identity resolved from its token; group assignments are not checked.'
        }
    } -Remedy 'Sign in as an attendee user and ensure Microsoft Graph can read the user and group membership.'
}

foreach ($subscription in $subscriptions) {
    Invoke-Check -Name "Role: $($subscription.Label)" -Action {
        if (-not $userId) { throw 'Cannot verify Owner without the signed-in user identity.' }
        $roles = Get-CallerAssignment -Scope "/subscriptions/$($subscription.Id)" -Subscription $subscription.Id
        if (-not ($roles | Where-Object { $_.roleDefinitionName -eq 'Owner' -and -not $_.condition })) {
            throw 'No unconditional Owner assignment found, including inherited and group assignments.'
        }
        Add-Result -Check "Role: $($subscription.Label)" -Status PASS -Reason 'Owner confirmed, including inherited and group assignments.'
    } -Remedy 'Have an administrator grant or activate Owner. In CSP, ask the partner (AOBO/GDAP) or a Global Admin with elevated access.'
}

if ($SharedSubscriptionId) {
    try {
        if (-not $userId -or -not $account) { throw 'Identity or tenant is unavailable.' }
        $parentId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $account.tenantId }
        $roles = Get-CallerAssignment -Scope "/providers/Microsoft.Management/managementGroups/$parentId" -Subscription $SharedSubscriptionId
        $rootManager = $roles | Where-Object {
            $_.roleDefinitionName -in @('Owner', 'Contributor', 'Management Group Contributor') -and -not $_.condition
        }
        $owners = @($results | Where-Object { $_.Check -like 'Role:*' -and $_.Status -eq 'PASS' })
        if (-not $rootManager -or $owners.Count -ne 2) {
            throw 'Root management rights and both subscription Owner roles could not be confirmed together.'
        }
        Add-Result -Check 'Management groups' -Status PASS -Reason 'Root management rights and subscription Owner roles permit creation and moves.'
    }
    catch {
        Add-Result -Check 'Management groups' -Status WARN -Reason "$($_.Exception.Message) Check Tenant Root and current parent IAM > Check access, and subscription move permissions." `
            -Remedy 'Ask the tenant administrator to confirm management-group creation and subscription moves before ALZ-lite.'
    }
}

$workload = $subscriptions | Where-Object { $_.Label -eq 'workload' }
$vmRestricted = $false
if ($workload) {
    Invoke-Check -Name 'VM size' -Action {
        $skus = @(Invoke-AzureCli @(
            'vm', 'list-skus', '--subscription', $WorkloadSubscriptionId,
            '--location', $targetLocation, '--size', 'Standard_D8as_v6', '--all'
        ))
        $size = @($skus | Where-Object { $_.name -eq 'Standard_D8as_v6' -and $_.resourceType -eq 'virtualMachines' })
        $restrictions = @($size | ForEach-Object { $_.restrictions })
        if ($size.Count -eq 0 -or ($restrictions | Where-Object { $_.type -ne 'Zone' })) {
            $script:vmRestricted = $true
            Add-Result -Check 'VM size' -Status WARN -Reason 'Standard_D8as_v6 is unavailable or restricted for non-zonal deployment; the size is a parameter.'
        }
        elseif ($restrictions.Count -gt 0) {
            Add-Result -Check 'VM size' -Status PASS -Reason 'Standard_D8as_v6 is available non-zonally; zone-only restrictions do not affect the kit.'
        }
        else {
            Add-Result -Check 'VM size' -Status PASS -Reason 'Standard_D8as_v6 is offered without restrictions.'
        }
    } -Remedy 'Check VM SKU access in the selected region; ask the platform lead about a supported size or region.'

    Invoke-Check -Name 'Region' -Action {
        # account list-locations has no --subscription option; avoid changing CLI context.
        $locations = (Invoke-AzureCli @(
            'rest', '--method', 'get', '--url',
            "/subscriptions/$WorkloadSubscriptionId/locations?api-version=2022-12-01"
        )).value
        $region = $locations | Where-Object { $_.name -eq $targetLocation }
        if (-not $region) { throw 'The selected region does not exist for this subscription.' }
        $sql = Invoke-AzureCli @('provider', 'show', '--namespace', 'Microsoft.Sql', '--subscription', $WorkloadSubscriptionId)
        $mi = $sql.resourceTypes | Where-Object { $_.resourceType -eq 'managedInstances' }
        if (-not ($mi.locations | Where-Object { ($_ -replace '\s', '') -eq ($region.name -replace '\s', '') -or $_ -eq $region.displayName })) {
            throw 'SQL Managed Instance is not offered in the selected region.'
        }
        Add-Result -Check 'Region' -Status PASS -Reason 'The selected region exists and offers SQL Managed Instance.'
    } -Remedy 'Choose a supported region; germanywestcentral is the documented fallback.'
}

$canRegister = -not ($results | Where-Object { $_.Status -eq 'FAIL' }) -and -not $vmRestricted
foreach ($subscription in $subscriptions) {
    Invoke-Check -Name "Resource providers: $($subscription.Label)" -Action {
        $registered = @(Invoke-AzureCli @('provider', 'list', '--subscription', $subscription.Id))
        $missing = @($providers | Where-Object {
            $namespace = $_
            -not ($registered | Where-Object { $_.namespace -eq $namespace -and $_.registrationState -eq 'Registered' })
        })
        if ($missing.Count -gt 0 -and $registerMissing -and $canRegister) {
            foreach ($namespace in $missing) {
                $null = Invoke-AzureCli @('provider', 'register', '--namespace', $namespace, '--subscription', $subscription.Id) -AllowEmpty
            }
            $deadline = [datetime]::UtcNow.AddMinutes(15)
            do {
                $registered = @(Invoke-AzureCli @('provider', 'list', '--subscription', $subscription.Id))
                $missing = @($missing | Where-Object {
                    $namespace = $_
                    -not ($registered | Where-Object { $_.namespace -eq $namespace -and $_.registrationState -eq 'Registered' })
                })
                if ($missing.Count -eq 0 -or [datetime]::UtcNow -ge $deadline) { break }
                Start-Sleep -Seconds 10
            } while ($true)
        }
        if ($missing.Count -gt 0) {
            throw "Providers not registered: $($missing -join ', '). Registration may be pending, timed out, or blocked by prerequisites."
        }
        Add-Result -Check "Resource providers: $($subscription.Label)" -Status PASS -Reason 'All 18 required providers are registered.'
    } -Remedy 'Resolve prerequisite failures, then rerun with -Fix. If registration fails or times out, ask the subscription administrator.'
}

$featureNamespace = 'Microsoft.Network'
$featureName = 'AllowBringYourOwnPublicIpAddress'
foreach ($subscription in $subscriptions) {
    Invoke-Check -Name "Public IP feature: $($subscription.Label)" -Action {
        function Get-FeatureState {
            (Invoke-AzureCli @('feature', 'show', '--namespace', $featureNamespace, '--name', $featureName, '--subscription', $subscription.Id)).properties.state
        }
        $state = Get-FeatureState
        if ($state -ne 'Registered' -and $registerMissing -and $canRegister) {
            if ($state -notin @('Registering', 'Pending')) {
                $null = Invoke-AzureCli @('feature', 'register', '--namespace', $featureNamespace, '--name', $featureName, '--subscription', $subscription.Id) -AllowEmpty
            }
            $deadline = [datetime]::UtcNow.AddMinutes(15)
            do {
                $state = Get-FeatureState
                if ($state -eq 'Registered' -or [datetime]::UtcNow -ge $deadline) { break }
                Start-Sleep -Seconds 10
            } while ($true)
            if ($state -eq 'Registered') {
                # The provider must be registered again before the feature takes effect.
                $null = Invoke-AzureCli @('provider', 'register', '--namespace', $featureNamespace, '--subscription', $subscription.Id) -AllowEmpty
            }
        }
        if ($state -ne 'Registered') {
            throw "The $featureNamespace/$featureName feature is $state. Firewall, NAT and Bastion public IPs fail without it (SubscriptionNotRegisteredForFeature)."
        }
        Add-Result -Check "Public IP feature: $($subscription.Label)" -Status PASS -Reason "$featureNamespace/$featureName is registered."
    } -Remedy 'Rerun with -Fix and wait; registration usually takes a few minutes. If it stays pending, ask the subscription administrator.'
}

Add-Result -Check 'MFA' -Status MANUAL -Reason 'Confirm MFA is registered for the account.'
Add-Result -Check 'GitHub Copilot' -Status MANUAL -Reason "Confirm a Copilot seat and org policies allowing agent mode, MCP servers and Copilot CLI."
Add-Result -Check 'GitHub repositories' -Status MANUAL -Reason "Confirm the account can create private repos in the partner's GitHub org."
Add-Result -Check 'APEX' -Status MANUAL -Reason 'Confirm Docker Desktop is available.'
Add-Result -Check 'Azure Hybrid Benefit' -Status MANUAL -Reason 'Confirm you hold eligible Windows Server licenses with Software Assurance. Azure Hybrid Benefit is on by default for vm-app01; without eligible licenses, deploy the datacenter with -NoHybridBenefit.'

$failures = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($OutFile) {
    try {
        [pscustomobject]@{
            Verdict = $(if ($failures -eq 0) { 'GO' } else { 'NO-GO' })
            FailureCount = $failures
            Checks = $results.ToArray()
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutFile -Encoding utf8
    }
    catch {
        Add-Result -Check 'JSON output' -Status FAIL -Reason 'Could not write the JSON report.' -Remedy 'Use an existing writable directory for -OutFile.'
        $failures++
    }
}
$results | Format-Table Check, Status, @{
    Label = 'Reason / fix'
    Expression = { if ($_.Fix) { "$($_.Reason) Fix: $($_.Fix)" } else { $_.Reason } }
} -Wrap | Out-String -Width 180 | Write-Output
if ($failures -eq 0) {
    Write-Output 'GO'
    exit 0
}
Write-Output "NO-GO: $failures failure(s)"
exit 1
