<#
.SYNOPSIS
Initializes the vm-app01 data disk as F: (GPT, NTFS, 64 KB clusters, label SQLData).
.DESCRIPTION
Runs as a VM run command (Windows PowerShell 5.1). Finds the data disk as the only raw disk,
because NVMe sizes number disks differently from their LUNs. Does nothing if F: is already SQLData.
.PARAMETER RunId
The deployment's run ID. It changes on every deployment so Azure re-runs the run command. Only logged.
.EXAMPLE
.\Initialize-AppDataDisk.ps1
#>
[CmdletBinding()]
param(
    [string] $RunId = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Initialize-AppDataDisk.log'

function Write-LabLog {
    param([string] $Message)
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $line
    Write-Output $line
}

try {
    Write-LabLog "Run ID: $RunId"
    $volume = Get-Volume -DriveLetter F -ErrorAction SilentlyContinue
    if ($volume) {
        if ($volume.FileSystemLabel -ne 'SQLData') {
            throw "F: already exists with label '$($volume.FileSystemLabel)', not SQLData."
        }
        Write-LabLog 'F: (SQLData) already exists. Nothing to do.'
        exit 0
    }

    $rawDisks = @(Get-Disk | Where-Object PartitionStyle -EQ 'RAW')
    if ($rawDisks.Count -ne 1) {
        throw "Expected exactly one raw disk, found $($rawDisks.Count)."
    }
    $disk = $rawDisks[0]
    Write-LabLog "Initializing disk $($disk.Number) ($([math]::Round($disk.Size / 1GB)) GiB) as F:."

    Initialize-Disk -Number $disk.Number -PartitionStyle GPT
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter F
    Format-Volume -Partition $partition -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel 'SQLData' -Confirm:$false | Out-Null

    Write-LabLog 'F: (SQLData) is ready.'
}
catch {
    Write-LabLog "ERROR: $($_.Exception.Message)"
    exit 1
}
