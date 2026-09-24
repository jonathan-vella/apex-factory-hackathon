<#
.SYNOPSIS
Checks vm-app01 from the inside: the app, F:, SQL Server, the MSMQ queue and the DB perf kit.
.DESCRIPTION
Sent by scripts/Test-Datacenter.ps1 through az vm run-command invoke (Windows PowerShell 5.1, as
SYSTEM). Prints one line per check: LABCHECK|PASS or FAIL|check|detail. Changes nothing.
.PARAMETER MinStudents
The fewest students the seeded database must hold.
.PARAMETER TargetStudents
The DB perf kit's student volume. The count must be within 5% of it.
.PARAMETER TargetEnrollments
The DB perf kit's enrollment volume. The count must be within 5% of it.
.EXAMPLE
.\Test-AppVm.ps1 -MinStudents 8 -TargetStudents 200000 -TargetEnrollments 2000000
#>
[CmdletBinding()]
param(
    [int] $MinStudents = 8,
    [int] $TargetStudents = 200000,
    [int] $TargetEnrollments = 2000000
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = 'C:\LabTools\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir 'Test-AppVm.log'

function Write-Check {
    param([string] $Check, [bool] $Pass, [string] $Detail)
    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    $line = "LABCHECK|$status|$Check|$Detail"
    Add-Content -Path $logFile -Value ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $line)
    Write-Output $line
}

function Invoke-Check {
    param([string] $Check, [scriptblock] $Test)
    try {
        $result = & $Test
        Write-Check -Check $Check -Pass $result[0] -Detail $result[1]
    }
    catch {
        Write-Check -Check $Check -Pass $false -Detail $_.Exception.Message
    }
}

function Invoke-Sql {
    param([string] $Query, [string] $Database = 'master')
    $connectionString = "Server=localhost;Database=$Database;Integrated Security=SSPI;Application Name=LabTools;Connect Timeout=15"
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        $table = New-Object System.Data.DataTable
        $table.Load($command.ExecuteReader())
        Write-Output -InputObject $table -NoEnumerate
    }
    finally {
        $connection.Dispose()
    }
}

Invoke-Check 'app: http://localhost/ returns 200 with Contoso University' {
    $response = Invoke-WebRequest -Uri 'http://localhost/' -UseBasicParsing -TimeoutSec 120
    @(($response.StatusCode -eq 200 -and $response.Content -match 'Contoso University'), "HTTP $($response.StatusCode)")
}

Invoke-Check 'app: F: exists' {
    $volume = Get-Volume -DriveLetter F -ErrorAction SilentlyContinue
    @([bool] $volume, $(if ($volume) { "$($volume.FileSystemLabel), $([math]::Round($volume.Size / 1GB)) GiB" } else { 'missing' }))
}

Invoke-Check 'app: ContosoUniversity files are on F:' {
    $files = @((Invoke-Sql "SELECT physical_name FROM sys.master_files WHERE database_id = DB_ID(N'ContosoUniversity')").Rows | ForEach-Object { $_.physical_name })
    $offF = @($files | Where-Object { $_ -notlike 'F:\*' })
    @(($files.Count -gt 0 -and $offF.Count -eq 0), ($files -join ', '))
}

Invoke-Check 'app: ContosoUniversity has the app tables' {
    $expected = 'Course', 'CourseAssignment', 'Department', 'Enrollment', 'Notification', 'OfficeAssignment', 'Person'
    $tables = @((Invoke-Sql -Database 'ContosoUniversity' "SELECT name FROM sys.tables").Rows | ForEach-Object { $_.name })
    $missing = @($expected | Where-Object { $tables -notcontains $_ })
    @(($missing.Count -eq 0), $(if ($missing.Count) { "missing: $($missing -join ', ')" } else { "$($tables.Count) tables" }))
}

Invoke-Check "app: at least $MinStudents students" {
    $count = (Invoke-Sql -Database 'ContosoUniversity' "SELECT COUNT(*) FROM dbo.Person WHERE Discriminator = N'Student'").Rows[0][0]
    @(($count -ge $MinStudents), "$count students")
}

Invoke-Check "perf kit: students within 5% of $TargetStudents" {
    $count = (Invoke-Sql -Database 'ContosoUniversity' "SELECT COUNT(*) FROM dbo.Person WHERE Discriminator = N'Student'").Rows[0][0]
    @(([math]::Abs($count - $TargetStudents) -le $TargetStudents * 0.05), "$count students")
}

Invoke-Check "perf kit: enrollments within 5% of $TargetEnrollments" {
    $count = (Invoke-Sql -Database 'ContosoUniversity' 'SELECT COUNT_BIG(*) FROM dbo.Enrollment').Rows[0][0]
    @(([math]::Abs($count - $TargetEnrollments) -le $TargetEnrollments * 0.05), "$count enrollments")
}

Invoke-Check 'perf kit: planted objects exist' {
    $expected = 'usp_SearchStudents', 'usp_GetStudentEnrollments', 'vw_EnrollmentStatistics'
    $objects = @((Invoke-Sql -Database 'ContosoUniversity' "SELECT name FROM sys.objects WHERE schema_id = SCHEMA_ID(N'dbo') AND type IN ('P', 'V')").Rows | ForEach-Object { $_.name })
    $missing = @($expected | Where-Object { $objects -notcontains $_ })
    @(($missing.Count -eq 0), $(if ($missing.Count) { "missing: $($missing -join ', ')" } else { $expected -join ', ' }))
}

Invoke-Check 'perf kit: compatibility level 110' {
    $level = (Invoke-Sql "SELECT compatibility_level FROM sys.databases WHERE name = N'ContosoUniversity'").Rows[0][0]
    @(($level -eq 110), "compatibility level $level")
}

Invoke-Check 'perf kit: Query Store read-write' {
    $state = (Invoke-Sql -Database 'ContosoUniversity' 'SELECT actual_state_desc FROM sys.database_query_store_options').Rows[0][0]
    @(($state -eq 'READ_WRITE'), "$state")
}

Invoke-Check 'app: availability groups (HADR) enabled' {
    $hadr = (Invoke-Sql "SELECT CAST(SERVERPROPERTY('IsHadrEnabled') AS int)").Rows[0][0]
    @(($hadr -eq 1), "IsHadrEnabled=$hadr")
}

Invoke-Check 'app: trace flags 1800 and 9567 on' {
    $flags = @((Invoke-Sql 'DBCC TRACESTATUS(-1) WITH NO_INFOMSGS').Rows | Where-Object { $_.Global -eq 1 } | ForEach-Object { [int] $_.TraceFlag })
    @((($flags -contains 1800) -and ($flags -contains 9567)), "global flags: $($flags -join ', ')")
}

Invoke-Check 'app: MSMQ queue exists' {
    $webConfig = New-Object System.Xml.XmlDocument
    $webConfig.Load('C:\inetpub\ContosoUniversity\Web.config')
    $queuePath = $webConfig.SelectSingleNode("/configuration/appSettings/add[@key='NotificationQueuePath']").GetAttribute('value')
    Add-Type -AssemblyName System.Messaging
    @([System.Messaging.MessageQueue]::Exists($queuePath), $queuePath)
}
