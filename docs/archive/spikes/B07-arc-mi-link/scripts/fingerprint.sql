-- ContosoUniversity fingerprint, run on the source and on the MI to compare them (B07 requirement 21).
-- Connect to the ContosoUniversity database.
SELECT s.name + N'.' + t.name AS TableName, SUM(p.rows) AS [RowCount]
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY TableName;

SELECT name AS DatabaseName, compatibility_level AS CompatibilityLevel,
       CAST(DATABASEPROPERTYEX(name, 'Updateability') AS nvarchar(20)) AS Updateability,
       recovery_model_desc AS RecoveryModel
FROM sys.databases
WHERE name = DB_NAME();

SELECT s.name + N'.' + o.name AS ObjectName, o.type_desc AS ObjectType
FROM sys.objects AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.name IN (N'usp_SearchStudents', N'usp_GetStudentEnrollments', N'vw_EnrollmentStatistics')
ORDER BY ObjectName;
