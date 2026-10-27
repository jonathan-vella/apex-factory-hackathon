#Requires -Version 7.4

<#
.SYNOPSIS
Redacts GUIDs from the output of a pipeline step, so a run log names no tenant, subscription, principal or resource.
.DESCRIPTION
Pipe a step's output through this script. Every GUID is replaced by <id:xxxx>, where xxxx is its first four characters, enough to
tell two values apart in a log without identifying anything. Other text passes through unchanged. Pipe with *>&1 so errors and
information messages are redacted too.
.EXAMPLE
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $id -WhatIf *>&1 | ./scripts/Write-RedactedOutput.ps1
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]
    [object] $InputObject
)

begin {
    $guidPattern = '\b([0-9a-fA-F]{4})[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'
}
process {
    [regex]::Replace("$InputObject", $guidPattern, '<id:$1>')
}
