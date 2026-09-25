#Requires -Version 7.4

<#
.SYNOPSIS
Runs the C9 workload against ContosoUniversity, so the planted performance issues show up in Query Store.
.DESCRIPTION
Runs on vm-dev01. Opens Concurrency connections and, for DurationMinutes, calls a weighted random mix
of the planted objects (dbo.usp_SearchStudents, dbo.usp_GetStudentEnrollments, dbo.vw_EnrollmentStatistics)
and app-like queries shaped like the ones the app's EF Core code sends (student search, student details
with enrollments, a student's enrollment statistics, the instructor page with course assignments), with
random students, departments and name fragments read from the database. It reads every row, like the
app. At the end it prints the calls, errors, average and 95th percentile duration per query type.
Point it at the source SQL Server before migration, or at SQL MI after cutover. Needs only the
SqlServer module, which it installs for the current user if it's missing.
.PARAMETER Server
The SQL Server to load. Defaults to the source, 10.10.n.4. After cutover, the SQL MI host name.
.PARAMETER MemberIndex
The member index n, 1-20, which sets the default Server.
.PARAMETER Authentication
SqlPassword connects as contosoapp with the password from the datacenter secrets file (source only).
ActiveDirectoryDefault uses the signed-in Entra identity, which SQL MI needs after cutover.
.PARAMETER DurationMinutes
How long to run.
.PARAMETER Concurrency
How many connections run queries at the same time.
.EXAMPLE
./db/perf-kit/Start-Workload.ps1 -MemberIndex 1
.EXAMPLE
./db/perf-kit/Start-Workload.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault
#>

[CmdletBinding()]
param(
    [string] $Server,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [ValidateSet('SqlPassword', 'ActiveDirectoryDefault')]
    [string] $Authentication = 'SqlPassword',
    [ValidateRange(1, 1440)]
    [int] $DurationMinutes = 15,
    [ValidateRange(1, 64)]
    [int] $Concurrency = 8
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
if (-not $Server) {
    $Server = "10.10.$MemberIndex.4"
}
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'PerfKit.psm1') -Force
Import-PerfKitSqlServer
$connectionString = Get-PerfKitConnectionString -Server $Server -Authentication $Authentication

# Query mix. Parameter says which random value a call gets. The app-like texts follow what EF Core 3.1 sends.
$queries = @(
    [pscustomobject]@{ Name = 'P2 dbo.usp_SearchStudents'; Weight = 15; Type = 'StoredProcedure'; Parameter = 'SearchProc'; Text = 'dbo.usp_SearchStudents' }
    [pscustomobject]@{ Name = 'P3 dbo.usp_GetStudentEnrollments'; Weight = 15; Type = 'StoredProcedure'; Parameter = 'StudentID'; Text = 'dbo.usp_GetStudentEnrollments' }
    [pscustomobject]@{ Name = 'P4 dbo.vw_EnrollmentStatistics'; Weight = 10; Type = 'Text'; Parameter = 'DepartmentID'; Text = @'
SELECT DepartmentName, CourseID, Title, Enrollments, GradedEnrollments, AverageGradePoint
FROM dbo.vw_EnrollmentStatistics
WHERE DepartmentID = @DepartmentID
ORDER BY AverageGradePoint DESC;
'@ }
    [pscustomobject]@{ Name = 'app: student search'; Weight = 15; Type = 'Text'; Parameter = 'AppSearch'; Text = @'
SELECT COUNT(*)
FROM [Person] AS [p]
WHERE ([p].[Discriminator] = N'Student') AND (((@__searchString_0 = N'') OR (CHARINDEX(@__searchString_0, [p].[LastName]) > 0)) OR ((@__searchString_0 = N'') OR (CHARINDEX(@__searchString_0, [p].[FirstName]) > 0)));
SELECT [p].[ID], [p].[Discriminator], [p].[FirstName], [p].[LastName], [p].[EnrollmentDate]
FROM [Person] AS [p]
WHERE ([p].[Discriminator] = N'Student') AND (((@__searchString_0 = N'') OR (CHARINDEX(@__searchString_0, [p].[LastName]) > 0)) OR ((@__searchString_0 = N'') OR (CHARINDEX(@__searchString_0, [p].[FirstName]) > 0)))
ORDER BY [p].[LastName]
OFFSET @__p_1 ROWS FETCH NEXT @__p_2 ROWS ONLY;
'@ }
    [pscustomobject]@{ Name = 'app: student details'; Weight = 20; Type = 'Text'; Parameter = 'StudentID'; Text = @'
SELECT [t].[ID], [t].[Discriminator], [t].[FirstName], [t].[LastName], [t].[EnrollmentDate], [t0].[EnrollmentID], [t0].[CourseID], [t0].[Grade], [t0].[StudentID], [t0].[CourseID0], [t0].[Credits], [t0].[DepartmentID], [t0].[TeachingMaterialImagePath], [t0].[Title]
FROM (
    SELECT TOP(2) [p].[ID], [p].[Discriminator], [p].[FirstName], [p].[LastName], [p].[EnrollmentDate]
    FROM [Person] AS [p]
    WHERE ([p].[Discriminator] = N'Student') AND ([p].[ID] = @StudentID)
) AS [t]
LEFT JOIN (
    SELECT [e].[EnrollmentID], [e].[CourseID], [e].[Grade], [e].[StudentID], [c].[CourseID] AS [CourseID0], [c].[Credits], [c].[DepartmentID], [c].[TeachingMaterialImagePath], [c].[Title]
    FROM [Enrollment] AS [e]
    INNER JOIN [Course] AS [c] ON [e].[CourseID] = [c].[CourseID]
) AS [t0] ON [t].[ID] = [t0].[StudentID]
ORDER BY [t].[ID], [t0].[EnrollmentID], [t0].[CourseID0];
'@ }
    [pscustomobject]@{ Name = 'app: enrollment statistics'; Weight = 15; Type = 'Text'; Parameter = 'StudentID'; Text = @'
SELECT COUNT(*) AS Enrollments, COUNT([e].[Grade]) AS GradedEnrollments, SUM([c].[Credits]) AS Credits, AVG(CAST(4 - [e].[Grade] AS decimal(4, 2))) AS GradePointAverage
FROM [Enrollment] AS [e]
INNER JOIN [Course] AS [c] ON [e].[CourseID] = [c].[CourseID]
WHERE [e].[StudentID] = @StudentID;
'@ }
    [pscustomobject]@{ Name = 'app: instructor page'; Weight = 10; Type = 'Text'; Parameter = 'None'; Text = @'
SELECT [p].[ID], [p].[Discriminator], [p].[FirstName], [p].[LastName], [p].[HireDate], [o].[InstructorID], [o].[Location], [t].[CourseID], [t].[InstructorID], [t].[CourseID0], [t].[Credits], [t].[DepartmentID], [t].[TeachingMaterialImagePath], [t].[Title], [t].[DepartmentID0], [t].[Budget], [t].[InstructorID0], [t].[Name], [t].[RowVersion], [t].[StartDate]
FROM [Person] AS [p]
LEFT JOIN [OfficeAssignment] AS [o] ON [p].[ID] = [o].[InstructorID]
LEFT JOIN (
    SELECT [c].[CourseID], [c].[InstructorID], [c0].[CourseID] AS [CourseID0], [c0].[Credits], [c0].[DepartmentID], [c0].[TeachingMaterialImagePath], [c0].[Title], [d].[DepartmentID] AS [DepartmentID0], [d].[Budget], [d].[InstructorID] AS [InstructorID0], [d].[Name], [d].[RowVersion], [d].[StartDate]
    FROM [CourseAssignment] AS [c]
    INNER JOIN [Course] AS [c0] ON [c].[CourseID] = [c0].[CourseID]
    INNER JOIN [Department] AS [d] ON [c0].[DepartmentID] = [d].[DepartmentID]
) AS [t] ON [p].[ID] = [t].[InstructorID]
WHERE [p].[Discriminator] = N'Instructor'
ORDER BY [p].[LastName], [p].[ID], [t].[CourseID], [t].[InstructorID], [t].[CourseID0];
'@ }
)

function Read-Column {
    param([Microsoft.Data.SqlClient.SqlConnection] $Connection, [string] $Query)
    $command = $Connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = 300
    $reader = $command.ExecuteReader()
    try {
        $values = [System.Collections.Generic.List[object]]::new()
        while ($reader.Read()) { $values.Add($reader.GetValue(0)) }
        return , $values.ToArray()
    }
    finally {
        $reader.Dispose()
        $command.Dispose()
    }
}

Write-Information "Reading random parameters from ContosoUniversity on $Server ($Authentication)."
$setup = [Microsoft.Data.SqlClient.SqlConnection]::new($connectionString)
$setup.Open()
try {
    $studentIds = Read-Column -Connection $setup -Query "SELECT ID FROM dbo.Person WHERE Discriminator = N'Student';"
    $departmentIds = Read-Column -Connection $setup -Query 'SELECT DepartmentID FROM dbo.Department;'
    $names = Read-Column -Connection $setup -Query "SELECT LastName FROM dbo.Person WHERE Discriminator = N'Student' UNION SELECT FirstName FROM dbo.Person WHERE Discriminator = N'Student';"
}
finally {
    $setup.Dispose()
}
# Search terms are the first 3 or 4 letters of real names, like a person typing a name.
$terms = @($names | ForEach-Object { $_.Substring(0, [math]::Min(3, $_.Length)); if ($_.Length -gt 4) { $_.Substring(0, 4) } } | Sort-Object -Unique)
if ($studentIds.Count -eq 0 -or $departmentIds.Count -eq 0) {
    throw 'ContosoUniversity has no students or departments. Is the perf kit installed?'
}

$started = [datetime]::UtcNow
$deadline = $started.AddMinutes($DurationMinutes)
Write-Information ("Running {0} connections for {1} minutes, until {2:HH:mm} UTC. {3:n0} students, {4} departments, {5} search terms." -f
    $Concurrency, $DurationMinutes, $deadline, $studentIds.Count, $departmentIds.Count, $terms.Count)

$workerResults = 1..$Concurrency | ForEach-Object -ThrottleLimit $Concurrency -Parallel {
    $queries = $using:queries
    $studentIds = $using:studentIds
    $departmentIds = $using:departmentIds
    $terms = $using:terms
    $deadline = $using:deadline
    $connectionString = $using:connectionString
    $random = [System.Random]::new()
    $totalWeight = ($queries | Measure-Object -Property Weight -Sum).Sum
    $durations = @{}
    $errors = @{}
    $lastError = @{}
    foreach ($query in $queries) {
        $durations[$query.Name] = [System.Collections.Generic.List[double]]::new()
        $errors[$query.Name] = 0
    }

    $connection = [Microsoft.Data.SqlClient.SqlConnection]::new($connectionString)
    $connection.Open()
    try {
        while ([datetime]::UtcNow -lt $deadline) {
            $pick = $random.Next($totalWeight)
            foreach ($query in $queries) {
                if ($pick -lt $query.Weight) { break }
                $pick -= $query.Weight
            }
            $command = $connection.CreateCommand()
            $command.CommandText = $query.Text
            $command.CommandType = $query.Type
            $command.CommandTimeout = 300
            switch ($query.Parameter) {
                'SearchProc' {
                    $command.Parameters.Add('@Term', [System.Data.SqlDbType]::NVarChar, 50).Value = $terms[$random.Next($terms.Count)]
                    $command.Parameters.Add('@PageNumber', [System.Data.SqlDbType]::Int).Value = 1 + $random.Next(3)
                }
                'AppSearch' {
                    $command.Parameters.Add('@__searchString_0', [System.Data.SqlDbType]::NVarChar, 50).Value = $terms[$random.Next($terms.Count)]
                    $command.Parameters.Add('@__p_1', [System.Data.SqlDbType]::Int).Value = 10 * $random.Next(3)
                    $command.Parameters.Add('@__p_2', [System.Data.SqlDbType]::Int).Value = 10
                }
                'StudentID' {
                    $command.Parameters.Add('@StudentID', [System.Data.SqlDbType]::Int).Value = $studentIds[$random.Next($studentIds.Count)]
                }
                'DepartmentID' {
                    $command.Parameters.Add('@DepartmentID', [System.Data.SqlDbType]::Int).Value = $departmentIds[$random.Next($departmentIds.Count)]
                }
            }
            $watch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $reader = $command.ExecuteReader()
                try {
                    do { while ($reader.Read()) { } } while ($reader.NextResult())
                }
                finally {
                    $reader.Dispose()
                }
                $durations[$query.Name].Add($watch.Elapsed.TotalMilliseconds)
            }
            catch {
                $errors[$query.Name]++
                $lastError[$query.Name] = $_.Exception.Message
                if ($connection.State -ne [System.Data.ConnectionState]::Open) {
                    $connection.Dispose()
                    $connection = [Microsoft.Data.SqlClient.SqlConnection]::new($connectionString)
                    $connection.Open()
                }
            }
            finally {
                $command.Dispose()
            }
        }
    }
    finally {
        $connection.Dispose()
    }
    [pscustomobject]@{ Durations = $durations; Errors = $errors; LastError = $lastError }
}

$summary = foreach ($query in $queries) {
    $all = [System.Collections.Generic.List[double]]::new()
    $errorCount = 0
    foreach ($worker in $workerResults) {
        $all.AddRange($worker.Durations[$query.Name])
        $errorCount += $worker.Errors[$query.Name]
    }
    $all.Sort()
    [pscustomobject]@{
        Query = $query.Name
        Calls = $all.Count
        Errors = $errorCount
        'Avg ms' = if ($all.Count) { [math]::Round(($all | Measure-Object -Average).Average, 1) } else { $null }
        'P95 ms' = if ($all.Count) { [math]::Round($all[[math]::Max(0, [math]::Ceiling($all.Count * 0.95) - 1)], 1) } else { $null }
    }
}

Write-Information ("Finished at {0:HH:mm} UTC after {1:n1} minutes: {2:n0} calls." -f [datetime]::UtcNow, ([datetime]::UtcNow - $started).TotalMinutes, ($summary | Measure-Object -Property Calls -Sum).Sum)
$summary | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
foreach ($worker in $workerResults) {
    foreach ($name in $worker.LastError.Keys) {
        Write-Warning "${name}: $($worker.LastError[$name])"
    }
}
Write-Information 'Look at the results in Query Store: in SSMS, ContosoUniversity > Query Store > Top Resource Consuming Queries.'
