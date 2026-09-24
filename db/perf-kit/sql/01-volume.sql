/*
    DB perf kit, step 1: volume.
    Adds about 200,000 students, 2,000 instructors, 40 departments, 4,000 courses, 8,000 course
    assignments, 2,000 office assignments and 2,000,000 enrollments on top of the app's seed data.
    Set-based and deterministic: every value comes from the row number, hashed with HASHBYTES, so
    every run gives the same rows. Seed rows use explicit IDs above the app's own, so the app's seed
    data stays intact and new app rows get IDs above the seed. Idempotent: rows that already exist are
    skipped, so a re-run finishes a partial seed. Enrollments go in batches of 10,000 students so the
    log stays small. The recovery model stays FULL, which MI link needs.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.Person', N'U') IS NULL OR OBJECT_ID(N'dbo.Enrollment', N'U') IS NULL
    THROW 50001, 'The app tables are missing. Warm up the app first: EnsureCreated() creates them.', 1;

DECLARE @studentBase int = 100000;      -- students are IDs 100001-300000
DECLARE @studentCount int = 200000;
DECLARE @instructorBase int = 10000;    -- instructors are IDs 10001-12000
DECLARE @instructorCount int = 2000;
DECLARE @departmentBase int = 100;      -- departments are IDs 101-140
DECLARE @courseBase int = 5000;         -- courses are 5001-9000
DECLARE @courseCount int = 4000;
DECLARE @enrollmentBase int = 1000000;  -- enrollment ID = base + (student - 1) * 12 + k, k = 1-12
DECLARE @batchSize int = 10000;
DECLARE @started datetime2 = SYSDATETIME();
DECLARE @message nvarchar(200);

CREATE TABLE #Number (n int NOT NULL PRIMARY KEY);
WITH e1 AS (SELECT 1 AS x FROM (VALUES (1), (1), (1), (1), (1), (1), (1), (1), (1), (1)) AS v (x)),
     e6 AS (SELECT 1 AS x FROM e1 AS a CROSS JOIN e1 AS b CROSS JOIN e1 AS c CROSS JOIN e1 AS d CROSS JOIN e1 AS e CROSS JOIN e1 AS f)
INSERT #Number (n)
SELECT TOP (@studentCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM e6;

CREATE TABLE #FirstName (i int NOT NULL PRIMARY KEY, name nvarchar(50) NOT NULL);
INSERT #FirstName (i, name)
SELECT ROW_NUMBER() OVER (ORDER BY v.name) - 1, v.name
FROM (VALUES
    (N'Aaliyah'), (N'Aaron'), (N'Abigail'), (N'Adam'), (N'Adrian'), (N'Ahmed'), (N'Aiden'), (N'Aisha'), (N'Alejandro'), (N'Alex'),
    (N'Alexander'), (N'Alice'), (N'Amelia'), (N'Ana'), (N'Andrea'), (N'Andrew'), (N'Anna'), (N'Anthony'), (N'Aria'), (N'Arjun'),
    (N'Ava'), (N'Benjamin'), (N'Bianca'), (N'Brandon'), (N'Camila'), (N'Carlos'), (N'Caroline'), (N'Charlotte'), (N'Chen'), (N'Chloe'),
    (N'Christopher'), (N'Claire'), (N'Daniel'), (N'David'), (N'Diego'), (N'Dylan'), (N'Elena'), (N'Eli'), (N'Elijah'), (N'Elizabeth'),
    (N'Ella'), (N'Emily'), (N'Emma'), (N'Eric'), (N'Ethan'), (N'Eva'), (N'Fatima'), (N'Felix'), (N'Gabriel'), (N'Grace'),
    (N'Hana'), (N'Hannah'), (N'Harper'), (N'Hassan'), (N'Henry'), (N'Ines'), (N'Isaac'), (N'Isabella'), (N'Ivan'), (N'Jack'),
    (N'Jacob'), (N'James'), (N'Javier'), (N'Jin'), (N'John'), (N'Jonathan'), (N'Jose'), (N'Joseph'), (N'Julia'), (N'Kai'),
    (N'Karen'), (N'Kevin'), (N'Laila'), (N'Laura'), (N'Leah'), (N'Leo'), (N'Liam'), (N'Lily'), (N'Lucas'), (N'Lucia'),
    (N'Luis'), (N'Maria'), (N'Mark'), (N'Mateo'), (N'Maya'), (N'Mei'), (N'Mia'), (N'Michael'), (N'Mohammed'), (N'Nadia'),
    (N'Natalie'), (N'Nathan'), (N'Nina'), (N'Noah'), (N'Nora'), (N'Oliver'), (N'Olivia'), (N'Omar'), (N'Oscar'), (N'Paul'),
    (N'Priya'), (N'Rachel'), (N'Rafael'), (N'Rahul'), (N'Rebecca'), (N'Riya'), (N'Robert'), (N'Ryan'), (N'Samuel'), (N'Sara'),
    (N'Sebastian'), (N'Sofia'), (N'Sophie'), (N'Thomas'), (N'Valentina'), (N'Victoria'), (N'William'), (N'Yara'), (N'Yuki'), (N'Zoe')
) AS v (name);

CREATE TABLE #LastName (i int NOT NULL PRIMARY KEY, name nvarchar(50) NOT NULL);
INSERT #LastName (i, name)
SELECT ROW_NUMBER() OVER (ORDER BY v.name) - 1, v.name
FROM (VALUES
    (N'Abbott'), (N'Adams'), (N'Ahmed'), (N'Ali'), (N'Allen'), (N'Alvarez'), (N'Andersen'), (N'Anderson'), (N'Bailey'), (N'Baker'),
    (N'Banerjee'), (N'Barnes'), (N'Becker'), (N'Bell'), (N'Bennett'), (N'Berg'), (N'Brooks'), (N'Brown'), (N'Butler'), (N'Campbell'),
    (N'Carter'), (N'Castillo'), (N'Chen'), (N'Clark'), (N'Collins'), (N'Cook'), (N'Cooper'), (N'Costa'), (N'Cruz'), (N'Dahl'),
    (N'Davies'), (N'Davis'), (N'Diaz'), (N'Dubois'), (N'Edwards'), (N'Eriksson'), (N'Evans'), (N'Fernandez'), (N'Fischer'), (N'Fisher'),
    (N'Flores'), (N'Foster'), (N'Garcia'), (N'Gomez'), (N'Gonzalez'), (N'Gray'), (N'Green'), (N'Gupta'), (N'Hall'), (N'Hansen'),
    (N'Harris'), (N'Hayes'), (N'Hernandez'), (N'Hill'), (N'Hoffmann'), (N'Howard'), (N'Hughes'), (N'Ito'), (N'Jackson'), (N'James'),
    (N'Jensen'), (N'Johansson'), (N'Johnson'), (N'Jones'), (N'Kaur'), (N'Kelly'), (N'Khan'), (N'Kim'), (N'King'), (N'Klein'),
    (N'Kowalski'), (N'Kumar'), (N'Larsen'), (N'Laurent'), (N'Lee'), (N'Lewis'), (N'Lindqvist'), (N'Lopez'), (N'Martin'), (N'Martinez'),
    (N'Meyer'), (N'Miller'), (N'Mitchell'), (N'Moore'), (N'Morales'), (N'Morgan'), (N'Morris'), (N'Murphy'), (N'Murray'), (N'Nakamura'),
    (N'Nguyen'), (N'Nielsen'), (N'Novak'), (N'Nowak'), (N'O''Brien'), (N'Olsen'), (N'Ortiz'), (N'Park'), (N'Parker'), (N'Patel'),
    (N'Perez'), (N'Perry'), (N'Petersen'), (N'Phillips'), (N'Popescu'), (N'Price'), (N'Ramirez'), (N'Reed'), (N'Reyes'), (N'Richardson'),
    (N'Rivera'), (N'Roberts'), (N'Robinson'), (N'Rodriguez'), (N'Rogers'), (N'Romano'), (N'Rossi'), (N'Russell'), (N'Sanchez'), (N'Sanders'),
    (N'Santos'), (N'Sato'), (N'Schmidt'), (N'Schneider'), (N'Scott'), (N'Shah'), (N'Silva'), (N'Singh'), (N'Smith'), (N'Stewart'),
    (N'Suzuki'), (N'Tanaka'), (N'Taylor'), (N'Thomas'), (N'Thompson'), (N'Torres'), (N'Turner'), (N'Walker'), (N'Wang'), (N'Ward'),
    (N'Watson'), (N'White'), (N'Williams'), (N'Wilson'), (N'Wood'), (N'Wright'), (N'Yamamoto'), (N'Young'), (N'Zhang'), (N'Zimmermann')
) AS v (name);

DECLARE @firstNames int = (SELECT COUNT(*) FROM #FirstName);
DECLARE @lastNames int = (SELECT COUNT(*) FROM #LastName);

-- Instructors, hired 1985-2024.
SET IDENTITY_INSERT dbo.Person ON;
INSERT dbo.Person (ID, LastName, FirstName, Discriminator, HireDate, EnrollmentDate)
SELECT @instructorBase + h.n, l.name, f.name, N'Instructor',
       DATEADD(DAY, h.r2 % 14600, CAST('1985-01-01' AS datetime2)), NULL
FROM (
    SELECT n.n,
           CAST(SUBSTRING(x.hb, 1, 4) AS int) & 2147483647 AS r0,
           CAST(SUBSTRING(x.hb, 5, 4) AS int) & 2147483647 AS r1,
           CAST(SUBSTRING(x.hb, 9, 4) AS int) & 2147483647 AS r2
    FROM #Number AS n
    CROSS APPLY (SELECT HASHBYTES('SHA2_256', N'instructor' + CAST(n.n AS nvarchar(10))) AS hb) AS x
    WHERE n.n <= @instructorCount
) AS h
JOIN #FirstName AS f ON f.i = h.r0 % @firstNames
JOIN #LastName AS l ON l.i = h.r1 % @lastNames
WHERE NOT EXISTS (SELECT 1 FROM dbo.Person AS p WHERE p.ID = @instructorBase + h.n);

-- Students: mostly autumn intakes 2005-2025, some spring intakes.
INSERT dbo.Person (ID, LastName, FirstName, Discriminator, HireDate, EnrollmentDate)
SELECT @studentBase + h.n, l.name, f.name, N'Student', NULL,
       CAST(DATEFROMPARTS(2005 + h.r2 % 21, CASE WHEN h.r3 % 5 = 0 THEN 2 ELSE 9 END, 1 + (h.r3 / 5) % 5) AS datetime2)
FROM (
    SELECT n.n,
           CAST(SUBSTRING(x.hb, 1, 4) AS int) & 2147483647 AS r0,
           CAST(SUBSTRING(x.hb, 5, 4) AS int) & 2147483647 AS r1,
           CAST(SUBSTRING(x.hb, 9, 4) AS int) & 2147483647 AS r2,
           CAST(SUBSTRING(x.hb, 13, 4) AS int) & 2147483647 AS r3
    FROM #Number AS n
    CROSS APPLY (SELECT HASHBYTES('SHA2_256', N'student' + CAST(n.n AS nvarchar(10))) AS hb) AS x
) AS h
JOIN #FirstName AS f ON f.i = h.r0 % @firstNames
JOIN #LastName AS l ON l.i = h.r1 % @lastNames
WHERE NOT EXISTS (SELECT 1 FROM dbo.Person AS p WHERE p.ID = @studentBase + h.n);
SET IDENTITY_INSERT dbo.Person OFF;
SET @message = CONCAT(N'People seeded after ', DATEDIFF(SECOND, @started, SYSDATETIME()), N' s.');
RAISERROR (@message, 0, 1) WITH NOWAIT;

-- Departments, each run by one of the new instructors.
CREATE TABLE #Department (i int NOT NULL PRIMARY KEY, name nvarchar(50) NOT NULL);
INSERT #Department (i, name)
SELECT ROW_NUMBER() OVER (ORDER BY v.name), v.name
FROM (VALUES
    (N'Accounting'), (N'Anthropology'), (N'Architecture'), (N'Art History'), (N'Astronomy'), (N'Biology'), (N'Business Administration'),
    (N'Chemical Engineering'), (N'Chemistry'), (N'Civil Engineering'), (N'Classics'), (N'Computer Science'), (N'Data Science'),
    (N'Education'), (N'Electrical Engineering'), (N'Environmental Science'), (N'Film Studies'), (N'Finance'), (N'Geography'),
    (N'Geology'), (N'History'), (N'Journalism'), (N'Law'), (N'Linguistics'), (N'Marketing'), (N'Mechanical Engineering'),
    (N'Medicine'), (N'Modern Languages'), (N'Music'), (N'Nursing'), (N'Pharmacology'), (N'Philosophy'), (N'Physics'),
    (N'Political Science'), (N'Psychology'), (N'Public Health'), (N'Religious Studies'), (N'Sociology'), (N'Statistics'), (N'Theatre')
) AS v (name);
DECLARE @departmentCount int = (SELECT COUNT(*) FROM #Department);

SET IDENTITY_INSERT dbo.Department ON;
INSERT dbo.Department (DepartmentID, Name, Budget, StartDate, InstructorID)
SELECT @departmentBase + d.i, d.name,
       50000 * (2 + (CAST(SUBSTRING(x.hb, 1, 4) AS int) & 2147483647) % 19),
       CAST(DATEFROMPARTS(1990 + (CAST(SUBSTRING(x.hb, 5, 4) AS int) & 2147483647) % 26, 9, 1) AS datetime2),
       @instructorBase + d.i * 50
FROM #Department AS d
CROSS APPLY (SELECT HASHBYTES('SHA2_256', N'department' + CAST(d.i AS nvarchar(10))) AS hb) AS x
WHERE NOT EXISTS (SELECT 1 FROM dbo.Department AS e WHERE e.DepartmentID = @departmentBase + d.i);
SET IDENTITY_INSERT dbo.Department OFF;

-- Courses: 100 per department, from 25 title patterns and 4 levels.
CREATE TABLE #TitlePattern (i int NOT NULL PRIMARY KEY, prefix nvarchar(30) NOT NULL, suffix nvarchar(20) NOT NULL);
INSERT #TitlePattern (i, prefix, suffix)
VALUES (0, N'Introduction to ', N''), (1, N'Advanced ', N''), (2, N'Topics in ', N''), (3, N'Foundations of ', N''),
       (4, N'', N' Seminar'), (5, N'Applied ', N''), (6, N'Principles of ', N''), (7, N'History of ', N''),
       (8, N'Research Methods in ', N''), (9, N'Modern ', N''), (10, N'', N' Laboratory'), (11, N'Contemporary ', N''),
       (12, N'Quantitative ', N''), (13, N'', N' Workshop'), (14, N'Theory of ', N''), (15, N'Case Studies in ', N''),
       (16, N'Survey of ', N''), (17, N'Ethics in ', N''), (18, N'Computational ', N''), (19, N'', N' Colloquium'),
       (20, N'Global ', N''), (21, N'Experimental ', N''), (22, N'Readings in ', N''), (23, N'', N' Capstone'),
       (24, N'Special Topics in ', N'');

INSERT dbo.Course (CourseID, Title, Credits, DepartmentID, TeachingMaterialImagePath)
SELECT @courseBase + n.n,
       t.prefix + d.name + t.suffix + CASE (n.n - 1) / 1000 WHEN 1 THEN N' II' WHEN 2 THEN N' III' WHEN 3 THEN N' IV' ELSE N'' END,
       CASE (CAST(SUBSTRING(x.hb, 1, 4) AS int) & 2147483647) % 10 WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 6 THEN 4 WHEN 7 THEN 4 WHEN 8 THEN 4 WHEN 9 THEN 5 ELSE 3 END,
       @departmentBase + d.i,
       NULL
FROM #Number AS n
JOIN #Department AS d ON d.i = 1 + (n.n - 1) % @departmentCount
JOIN #TitlePattern AS t ON t.i = ((n.n - 1) / @departmentCount) % 25
CROSS APPLY (SELECT HASHBYTES('SHA2_256', N'course' + CAST(n.n AS nvarchar(10))) AS hb) AS x
WHERE n.n <= @courseCount
  AND NOT EXISTS (SELECT 1 FROM dbo.Course AS c WHERE c.CourseID = @courseBase + n.n);

-- Two instructors per course. 7 and 2,000 are coprime, so every new instructor teaches exactly four courses.
INSERT dbo.CourseAssignment (InstructorID, CourseID)
SELECT a.InstructorID, a.CourseID
FROM #Number AS n
CROSS APPLY (VALUES (@instructorBase + 1 + (n.n * 7) % @instructorCount, @courseBase + n.n),
                    (@instructorBase + 1 + (n.n * 7 + @instructorCount / 2) % @instructorCount, @courseBase + n.n)) AS a (InstructorID, CourseID)
WHERE n.n <= @courseCount
  AND NOT EXISTS (SELECT 1 FROM dbo.CourseAssignment AS c WHERE c.CourseID = a.CourseID AND c.InstructorID = a.InstructorID);

-- One office per new instructor.
INSERT dbo.OfficeAssignment (InstructorID, Location)
SELECT @instructorBase + n.n,
       CHOOSE(1 + (CAST(SUBSTRING(x.hb, 1, 4) AS int) & 2147483647) % 10,
              N'Smith', N'Gowan', N'Thompson', N'Harrison', N'Kingsley', N'Newton', N'Curie', N'Darwin', N'Lovelace', N'Turing')
           + N' ' + CAST(100 + (CAST(SUBSTRING(x.hb, 5, 4) AS int) & 2147483647) % 400 AS nvarchar(10))
FROM #Number AS n
CROSS APPLY (SELECT HASHBYTES('SHA2_256', N'office' + CAST(n.n AS nvarchar(10))) AS hb) AS x
WHERE n.n <= @instructorCount
  AND NOT EXISTS (SELECT 1 FROM dbo.OfficeAssignment AS o WHERE o.InstructorID = @instructorBase + n.n);
SET @message = CONCAT(N'Departments, courses and assignments seeded after ', DATEDIFF(SECOND, @started, SYSDATETIME()), N' s.');
RAISERROR (@message, 0, 1) WITH NOWAIT;

-- Enrollments: 8-12 per student, 10 on average. Grades: A 20%, B 30%, C 25%, D 12%, F 6%, no grade yet 7%.
DECLARE @batchStart int = 1;
SET IDENTITY_INSERT dbo.Enrollment ON;
WHILE @batchStart <= @studentCount
BEGIN
    INSERT dbo.Enrollment (EnrollmentID, CourseID, StudentID, Grade)
    SELECT @enrollmentBase + (s.n - 1) * 12 + k.k,
           @courseBase + 1 + (s.n * 131 + k.k * 397) % @courseCount,
           @studentBase + s.n,
           CASE WHEN g.r < 20 THEN 0 WHEN g.r < 50 THEN 1 WHEN g.r < 75 THEN 2 WHEN g.r < 87 THEN 3 WHEN g.r < 93 THEN 4 END
    FROM #Number AS s
    CROSS JOIN (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS k (k)
    CROSS APPLY (SELECT (CAST(SUBSTRING(HASHBYTES('MD5', CAST(s.n AS binary(4)) + CAST(k.k AS binary(1))), 1, 4) AS int) & 2147483647) % 100 AS r) AS g
    WHERE s.n BETWEEN @batchStart AND @batchStart + @batchSize - 1
      AND k.k <= 8 + s.n % 5
      AND NOT EXISTS (SELECT 1 FROM dbo.Enrollment AS e WHERE e.EnrollmentID = @enrollmentBase + (s.n - 1) * 12 + k.k);
    CHECKPOINT;
    SET @batchStart += @batchSize;
END;
SET IDENTITY_INSERT dbo.Enrollment OFF;

SET @message = CONCAT(N'Volume seeded in ', DATEDIFF(SECOND, @started, SYSDATETIME()), N' s: ',
    (SELECT COUNT(*) FROM dbo.Person WHERE Discriminator = N'Student'), N' students, ',
    (SELECT COUNT(*) FROM dbo.Enrollment), N' enrollments.');
RAISERROR (@message, 0, 1) WITH NOWAIT;
