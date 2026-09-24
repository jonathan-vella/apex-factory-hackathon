/*
    DB perf kit, step 3: P5, the outdated compatibility level.
    110 is SQL Server 2012. It keeps the legacy cardinality estimator and turns off newer optimizer
    features such as scalar UDF inlining and batch mode on rowstore, which makes P4 worse. The app's
    EF Core queries work at 110. MI link keeps the level, so the issue survives the migration.
    Idempotent.
*/
SET NOCOUNT ON;

IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()) <> 110
    ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 110;
