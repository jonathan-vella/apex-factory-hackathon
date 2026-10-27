#Requires -Version 7.4

<#
.SYNOPSIS
Runs regression tests for Write-RedactedOutput.ps1, never against Azure.
.EXAMPLE
./test/Write-RedactedOutput.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Write-RedactedOutput.ps1'
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$id = '12345678-90ab-cdef-1234-567890abcdef'

$text = "principalId $id and /subscriptions/$($id.ToUpper())/resourceGroups/rg" | & $script
Assert-True ($text -notmatch '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}') 'A GUID survived the filter.'
Assert-True ($text -match '<id:1234>' -and $text -match '<id:1234>/resourceGroups/rg') 'The first four characters should stay, in either case.'
$passed++

$plain = 'Deployment of rg-hub finished in 4 minutes.' | & $script
Assert-True ($plain -eq 'Deployment of rg-hub finished in 4 minutes.') 'Plain text should pass through unchanged.'
$passed++

$records = @(& {
        Write-Information "id $id"
        Write-Warning "warn $id"
        Write-Output "out $id"
    } *>&1 | & $script)
Assert-True ($records.Count -eq 3) 'Every stream should reach the filter.'
Assert-True (-not ($records -match $id)) 'A GUID from an information, warning or output record survived.'
$passed++

$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$failing = Join-Path ([System.IO.Path]::GetTempPath()) "redact-test-$([guid]::NewGuid().ToString('N')).ps1"
try {
    Set-Content -Path $failing -Value "Write-Output 'before'; exit 7"
    $null = & $pwsh -NoProfile -Command "& '$failing' *>&1 | & '$script'; exit `$LASTEXITCODE"
    Assert-True ($LASTEXITCODE -eq 7) "The exit code of the step's script should survive the pipe (got $LASTEXITCODE)."
}
finally {
    Remove-Item -Path $failing -Force -ErrorAction SilentlyContinue
}
$passed++

Write-Information "Write-RedactedOutput: $passed scenarios passed." -InformationAction Continue
