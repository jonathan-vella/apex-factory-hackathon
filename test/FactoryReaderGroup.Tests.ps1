#Requires -Version 7.4

<#
.SYNOPSIS
Regression tests for the Entra group and Azure assignment helpers using in-process stubs, never Azure or GitHub.
.EXAMPLE
./test/FactoryReaderGroup.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scripts = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
. (Join-Path $scripts 'FactoryReaderAccess.ps1')
$sync = Join-Path $scripts 'Sync-FactoryReaderGroup.ps1'
$fakeId = { param($n) '{0:x8}-0000-0000-0000-000000000000' -f $n }
$tenant = & $fakeId 101
$groupId = & $fakeId 102
$currentUser = & $fakeId 103
$departedUser = & $fakeId 104
$nestedGroup = & $fakeId 105
$owner = & $fakeId 106
$scope = '/providers/Microsoft.Management/managementGroups/mg-test'
$work = New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) "factory-readers-$([guid]::NewGuid())")
$rosterPath = Join-Path $work.FullName 'roster.csv'
$state = @{
    Group = $null; Members = [Collections.Generic.List[string]]::new()
    Calls = [Collections.Generic.List[string]]::new(); Writes = [Collections.Generic.List[string]]::new()
    RejectAdds = $false; ContextTenant = $tenant
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
}

function Get-MgContext {
    @{ TenantId = $state.ContextTenant; AuthType = 'Delegated'; ContextScope = 'Process' }
}

function Invoke-MgGraphRequest {
    param($Method, $Uri, $Headers, $OutputType, $SkipHttpErrorCheck, $Body, $ContentType)
    [void] $state.Calls.Add("$Method $Uri")
    $payload = if ($Body) { $Body | ConvertFrom-Json -AsHashtable }
    $status = 200
    $data = switch -Wildcard ("$Method $Uri") {
        'GET */groups(uniqueName=*' {
            if (-not $state.Group) { $status = 404 }
            $state.Group
        }
        'PATCH */groups(uniqueName=*' {
            if ($Headers.Prefer -ne 'create-if-missing') { throw 'Expected an alternate-key upsert.' }
            [void] $state.Writes.Add('create')
            $state.Group = $payload + @{ id = $groupId; uniqueName = $payload.displayName }
            $status = 201
            $state.Group
        }
        'GET */owners?*' { @{ value = @(@{ id = $owner }) } }
        'POST */directoryObjects/getByIds' {
            @{ value = @(foreach ($id in $payload.ids) {
                    if ($id -eq $currentUser) { @{ id = $id; '@odata.type' = '#microsoft.graph.user' } }
                    elseif ($id -eq $nestedGroup) { @{ id = $id; '@odata.type' = '#microsoft.graph.group'; securityEnabled = $true; mailEnabled = $false } }
                }) }
        }
        'GET */members?*' { @{ value = @($state.Members | ForEach-Object { @{ id = $_ } }) } }
        'GET */groups/*' { @{ id = $nestedGroup; securityEnabled = $true; mailEnabled = $false } }
        'PATCH */groups/*' {
            [void] $state.Writes.Add('batch add')
            if ($state.RejectAdds) { $status = 400; @{ error = @{ message = 'invalid group' } } }
            else {
                foreach ($memberRef in $payload['members@odata.bind']) { [void] $state.Members.Add(($memberRef -split '/')[-1]) }
                $status = 204
            }
        }
        'POST */members/*' { [void] $state.Writes.Add('single add'); $status = 400; @{ error = @{ message = 'invalid group' } } }
        'DELETE */members/*/$ref' {
            [void] $state.Writes.Add('remove reference')
            [void] $state.Members.Remove(($Uri -split '/')[-2])
            $status = 204
        }
        default { throw "Unstubbed Graph request: $Method $Uri" }
    }
    $response = [Net.Http.HttpResponseMessage]::new([Net.HttpStatusCode] $status)
    $response.Content = [Net.Http.StringContent]::new($(if ($data) { ConvertTo-Json -InputObject $data -Depth 6 -Compress } else { '' }))
    $response
}

try {
    $common = @{ TenantId = $tenant; MgPrefix = 'mg-test'; UseExistingSession = $true }
    & $sync @common -Mode Bootstrap -OwnerId $owner -WhatIf
    Assert-True (-not $state.Writes.Count) 'bootstrap preview must not write'
    & $sync @common -Mode Bootstrap -OwnerId $owner
    & $sync @common -Mode Bootstrap -OwnerId $owner
    Assert-True ($state.Writes.Count -eq 1 -and -not $state.Members.Count) 'bootstrap should create one empty group, then be idempotent'
    $state.Members.Add($departedUser)
    $csvHeader = 'Member index,Workload subscription ID,Entra object ID,Budget email'
    Set-Content -LiteralPath $rosterPath -Value @($csvHeader, "1,$(& $fakeId 201),,lead@example.test")
    $failure = try { & $sync @common -Mode Sync -RosterPath $rosterPath; '' } catch { $_.Exception.Message }
    Assert-True ($failure -match 'Member 1 has no valid' -and $departedUser -in $state.Members) 'an incomplete roster must not remove anyone'
    Set-Content -LiteralPath $rosterPath -Value @($csvHeader, "1,$(& $fakeId 201),$currentUser,lead@example.test", "2,$(& $fakeId 202),$nestedGroup,lead@example.test")
    $state.Writes.Clear()
    & $sync @common -Mode Sync -RosterPath $rosterPath -WhatIf
    Assert-True (-not $state.Writes.Count) 'sync preview must not write'
    $state.RejectAdds = $true
    $failure = try { & $sync @common -Mode Sync -RosterPath $rosterPath; '' } catch { $_.Exception.Message }
    Assert-True ($failure -match 'roster index' -and $departedUser -in $state.Members) 'a rejected batch must isolate an entry and not attempt removals'
    $state.RejectAdds = $false
    $state.Writes.Clear()
    & $sync @common -Mode Sync -RosterPath $rosterPath
    Assert-True ($state.Writes -join ',' -eq 'batch add,remove reference' -and $state.Members.Count -eq 2) 'sync should reconcile additions and removals, using /$ref for removal'
    $state.Writes.Clear()
    & $sync @common -Mode Sync -RosterPath $rosterPath
    Assert-True (-not $state.Writes.Count) 'a second sync must not change memberships'
    Assert-True (& $sync @common -Mode Verify -ExpectedGroupId $groupId -MemberPrincipalId $nestedGroup) 'a direct nested security group should verify read-only'
    $failure = try { & $sync @common -Mode Verify -ExpectedGroupId (& $fakeId 999) -MemberPrincipalId $nestedGroup; '' } catch { $_.Exception.Message }
    Assert-True ($failure -match 'does not match the expected reader group') 'a recreated group with a different object ID must not pass verification'
    $state.ContextTenant = & $fakeId 999
    $failure = try { & $sync @common -Mode Sync -RosterPath $rosterPath; '' } catch { $_.Exception.Message }
    Assert-True ($failure -match 'intended tenant' -and -not $state.Writes.Count) 'a mismatched Graph tenant must block mutations'

    $binding = @{
        name = Get-FactoryAssignmentName -Scope $scope -PrincipalId $groupId
        scope = $scope; principalId = $groupId; principalType = 'Group'
        roleDefinitionId = "/providers/Microsoft.Authorization/roleDefinitions/$factoryReaderRole"; description = $factoryReaderMarker
    }
    $legacy = $binding.Clone()
    $legacy.principalId = $nestedGroup
    $legacy.description = $factoryLegacyReaderMarker
    $legacy.name = Get-FactoryAssignmentName -Scope $scope -PrincipalId $nestedGroup -Legacy
    Assert-True (Test-FactoryReaderAssignment -Assignment $binding -Scope $scope -GroupId $groupId) 'the exact new group binding should match'
    Assert-True (Test-FactoryReaderAssignment -Assignment $legacy -Scope $scope -Legacy) 'a legacy group principal and marker should still be recognized'
    Assert-True (-not (Test-FactoryReaderAssignment -Assignment $binding -Scope $scope -Legacy)) 'migration must not select the new binding'
    Assert-True (-not (Test-FactoryReaderAssignment -Assignment $binding -Scope "$scope-corp")) 'a child scope must not match'
    $legacy.name = & $fakeId 111
    Assert-True (-not (Test-FactoryReaderAssignment -Assignment $legacy -Scope $scope -Legacy)) 'a marker alone is not enough to delete a grant'
    Write-Output 'PASS: reader group bootstrap, roster reconciliation, and exact Azure grant ownership (no live calls).'
}
finally {
    Remove-Item -LiteralPath $rosterPath -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $work.FullName
}
