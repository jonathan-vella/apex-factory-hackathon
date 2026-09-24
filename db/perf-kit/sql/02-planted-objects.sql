/*
    DB perf kit, step 2: the planted objects.
    P1: no non-clustered index on Enrollment.StudentID. EnsureCreated() adds IX_Enrollment_StudentID
        for the foreign key, so this drops it.
    P2: dbo.usp_SearchStudents searches names with LIKE '%' + @Term + '%', which can't seek.
    P3: dbo.usp_GetStudentEnrollments takes @StudentID as sql_variant, so the int column is converted
        (CONVERT_IMPLICIT on the column) and even an index on StudentID is scanned.
    P4: dbo.vw_EnrollmentStatistics calls the scalar function dbo.ufn_GradePoint once per row, which
        forces a serial plan.
    Idempotent: the objects are dropped and created again, so this also puts back a fixed version.
    The app doesn't use any of them.
*/
SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Enrollment') AND name = N'IX_Enrollment_StudentID')
    DROP INDEX IX_Enrollment_StudentID ON dbo.Enrollment;

IF OBJECT_ID(N'dbo.vw_EnrollmentStatistics') IS NOT NULL
    DROP VIEW dbo.vw_EnrollmentStatistics;
IF OBJECT_ID(N'dbo.ufn_GradePoint') IS NOT NULL
    DROP FUNCTION dbo.ufn_GradePoint;
IF OBJECT_ID(N'dbo.usp_SearchStudents') IS NOT NULL
    DROP PROCEDURE dbo.usp_SearchStudents;
IF OBJECT_ID(N'dbo.usp_GetStudentEnrollments') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetStudentEnrollments;
GO

-- Grade points for a grade: A (0) is 4.0 down to F (4) at 0.0. NULL means no grade yet.
CREATE FUNCTION dbo.ufn_GradePoint (@Grade int)
RETURNS decimal(3, 2)
AS
BEGIN
    DECLARE @Points decimal(3, 2);
    SET @Points = CASE @Grade
        WHEN 0 THEN 4.0
        WHEN 1 THEN 3.0
        WHEN 2 THEN 2.0
        WHEN 3 THEN 1.0
        WHEN 4 THEN 0.0
    END;
    RETURN @Points;
END;
GO

-- Enrollment statistics per course, for the department reports.
CREATE VIEW dbo.vw_EnrollmentStatistics
AS
SELECT d.DepartmentID,
       d.Name AS DepartmentName,
       c.CourseID,
       c.Title,
       COUNT(*) AS Enrollments,
       COUNT(e.Grade) AS GradedEnrollments,
       AVG(dbo.ufn_GradePoint(e.Grade)) AS AverageGradePoint
FROM dbo.Enrollment AS e
JOIN dbo.Course AS c ON c.CourseID = e.CourseID
JOIN dbo.Department AS d ON d.DepartmentID = c.DepartmentID
GROUP BY d.DepartmentID, d.Name, c.CourseID, c.Title;
GO

-- Student search: first or last name contains the term, one page at a time.
CREATE PROCEDURE dbo.usp_SearchStudents
    @Term nvarchar(50),
    @PageNumber int = 1,
    @PageSize int = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.ID, p.LastName, p.FirstName, p.EnrollmentDate, COUNT(*) OVER () AS TotalCount
    FROM dbo.Person AS p
    WHERE p.Discriminator = N'Student'
      AND (p.LastName LIKE N'%' + @Term + N'%' OR p.FirstName LIKE N'%' + @Term + N'%')
    ORDER BY p.LastName, p.FirstName, p.ID
    OFFSET (@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

-- A student's enrollments with course titles and credits.
CREATE PROCEDURE dbo.usp_GetStudentEnrollments
    @StudentID sql_variant
AS
BEGIN
    SET NOCOUNT ON;
    SELECT e.EnrollmentID, e.CourseID, c.Title, c.Credits, e.Grade
    FROM dbo.Enrollment AS e
    JOIN dbo.Course AS c ON c.CourseID = e.CourseID
    WHERE e.StudentID = @StudentID
    ORDER BY c.Title;
END;
GO
