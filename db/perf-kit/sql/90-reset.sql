/*
    DB perf kit reset, the last step: run it after 02, 03 and 04, as db/perf-kit/Reset-PerfKit.ps1 does.
    02 puts back the planted objects and drops IX_Enrollment_StudentID, 03 the compatibility level and
    04 the Query Store settings. This drops every index added to the app's tables since EnsureCreated(),
    whatever its name, and then clears Query Store, so the next workload run starts from nothing.
    Idempotent.
*/
SET NOCOUNT ON;

DECLARE @sql nvarchar(max) = N'';
SELECT @sql += N'DROP INDEX ' + QUOTENAME(i.name) + N' ON dbo.' + QUOTENAME(t.name) + N';' + NCHAR(10)
FROM sys.indexes AS i
JOIN sys.tables AS t ON t.object_id = i.object_id
WHERE t.schema_id = SCHEMA_ID(N'dbo')
  AND t.name IN (N'Course', N'CourseAssignment', N'Department', N'Enrollment', N'Notification', N'OfficeAssignment', N'Person')
  AND i.index_id > 0
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0
  AND i.name NOT IN (N'IX_Course_DepartmentID', N'IX_CourseAssignment_InstructorID', N'IX_Department_InstructorID', N'IX_Enrollment_CourseID');

IF @sql <> N''
BEGIN
    RAISERROR (N'Dropping added indexes:', 0, 1) WITH NOWAIT;
    PRINT @sql;
    EXEC sys.sp_executesql @sql;
END;

ALTER DATABASE CURRENT SET QUERY_STORE CLEAR;
RAISERROR (N'Query Store cleared.', 0, 1) WITH NOWAIT;
