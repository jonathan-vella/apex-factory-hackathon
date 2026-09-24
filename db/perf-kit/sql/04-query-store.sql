/*
    DB perf kit, step 4: Query Store, sized for a 2-day event.
    Read-write, capturing every query, with 5-minute intervals so a 15-minute workload run shows up
    as three intervals, a 1-minute flush and 2 GB of storage. Idempotent.
*/
SET NOCOUNT ON;

ALTER DATABASE CURRENT SET QUERY_STORE = ON;
ALTER DATABASE CURRENT SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE,
    QUERY_CAPTURE_MODE = ALL,
    INTERVAL_LENGTH_MINUTES = 5,
    DATA_FLUSH_INTERVAL_SECONDS = 60,
    MAX_STORAGE_SIZE_MB = 2048,
    SIZE_BASED_CLEANUP_MODE = AUTO,
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 14),
    MAX_PLANS_PER_QUERY = 200,
    WAIT_STATS_CAPTURE_MODE = ON
);
