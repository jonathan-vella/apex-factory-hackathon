/*
    DB perf kit: Query Store snapshot for C9 before/after evidence. Read-only except an optional flush.

    Run it in SSMS or the MSSQL extension, connected to the ContosoUniversity database (the source SQL
    Server before cutover, SQL MI after). Run it twice, with the same window length and the same workload
    (Start-Workload.ps1 with the same -DurationMinutes and -Concurrency): once after the baseline run, and
    once after each fix and re-run. Save each result grid, with its label and window, as evidence.

    How to read it
    - Query Store aggregates into 5-minute intervals (see 04-query-store.sql). Only intervals that start
      and end inside your window count. Set @FromUtc to the five-minute mark at or before the workload
      run's start and @ToUtc to the five-minute mark at or after its end, for example a run that started
      at 09:03 and ended at 09:08 gets 09:00 to 09:10. Don't run anything else against the database in
      that window.
    - Averages are weighted by execution count. Duration and CPU are in milliseconds, logical reads are
      8 KB pages per execution.
    - A fix can change a query's plan, so compare by object or query text, not only by plan_id.
    - This is workload evidence on a shared system, not a controlled benchmark. Treat small differences
      with caution.
*/
SET NOCOUNT ON;

DECLARE @Label nvarchar(100) = N'baseline';
-- Window, in UTC. Replace with exact times, for example '2026-10-14T09:00:00+00:00'.
DECLARE @FromUtc datetimeoffset = DATEADD(MINUTE, -30, SYSDATETIMEOFFSET());
DECLARE @ToUtc datetimeoffset = SYSDATETIMEOFFSET();
DECLARE @Top int = 15;

-- Query Store keeps recent data in memory and flushes it every minute. Run this once after a workload
-- run, wait a few seconds, then run the rest, so the last interval is on disk. It changes no data.
-- EXEC sys.sp_query_store_flush_db;

SELECT
    actual_state_desc AS query_store_state,
    interval_length_minutes,
    flush_interval_seconds,
    @Label AS label,
    @FromUtc AS window_from_utc,
    @ToUtc AS window_to_utc
FROM sys.database_query_store_options;

SELECT
    COUNT(*) AS intervals_in_window,
    MIN(start_time) AS first_interval_start_utc,
    MAX(end_time) AS last_interval_end_utc
FROM sys.query_store_runtime_stats_interval
WHERE start_time >= @FromUtc AND end_time <= @ToUtc;

SELECT TOP (@Top)
    @Label AS label,
    q.query_id,
    p.plan_id,
    OBJECT_NAME(q.object_id) AS object_name,
    LEFT(REPLACE(REPLACE(qt.query_sql_text, CHAR(13), N' '), CHAR(10), N' '), 100) AS query_text,
    SUM(rs.count_executions) AS executions,
    SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS avg_duration_ms,
    SUM(rs.avg_cpu_time * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS avg_cpu_ms,
    SUM(rs.avg_logical_io_reads * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) AS avg_logical_reads_pages,
    SUM(rs.avg_duration * rs.count_executions) / 1000.0 AS total_duration_ms
FROM sys.query_store_runtime_stats AS rs
INNER JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
INNER JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
INNER JOIN sys.query_store_query AS q ON q.query_id = p.query_id
INNER JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
WHERE i.start_time >= @FromUtc
    AND i.end_time <= @ToUtc
    AND rs.execution_type = 0
GROUP BY q.query_id, p.plan_id, q.object_id, qt.query_sql_text
ORDER BY total_duration_ms DESC;
