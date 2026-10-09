# Replica and cutover checks

Outputs of [../scripts/fingerprint.sql](../scripts/fingerprint.sql) and the post-cutover comparison, run from `vm-dev01` through [../scripts/Invoke-MiQuery.ps1](../scripts/Invoke-MiQuery.ps1) on 2026-10-02 (times UTC+2). The source is `vm-app01` (SQL authentication as `contosoapp`); the MI is reached by its private host name as the Entra admin. Host names are left out.

## Source baseline (13:03) and replica, link 1 (13:18)

The same on both, except updateability:

```json
[{"TableName":"dbo.Course","RowCount":4007},{"TableName":"dbo.CourseAssignment","RowCount":8008},{"TableName":"dbo.Department","RowCount":44},{"TableName":"dbo.Enrollment","RowCount":2000011},{"TableName":"dbo.Notification","RowCount":0},{"TableName":"dbo.OfficeAssignment","RowCount":2003},{"TableName":"dbo.Person","RowCount":202013}]
[{"DatabaseName":"ContosoUniversity","CompatibilityLevel":110,"Updateability":"READ_ONLY","RecoveryModel":"FULL"}]
[{"ObjectName":"dbo.usp_GetStudentEnrollments","ObjectType":"SQL_STORED_PROCEDURE"},{"ObjectName":"dbo.usp_SearchStudents","ObjectType":"SQL_STORED_PROCEDURE"},{"ObjectName":"dbo.vw_EnrollmentStatistics","ObjectType":"VIEW"}]
```

The source showed `READ_WRITE`; the replica `READ_ONLY`. Link 2's replica (13:47) returned the same.

## After the abort (13:28–13:30)

| | Source | MI |
|---|---|---|
| `ContosoUniversity` | `ONLINE`, `READ_WRITE`, fingerprint unchanged | `ONLINE`, `READ_WRITE` (left behind by **Cancel migration**) |
| Availability groups | None | None |
| App `/Students` from `vm-dev01` | HTTP 200 | — |

## After cutover (14:00–14:02)

| | Source | MI |
|---|---|---|
| `ContosoUniversity` | `ONLINE`, `READ_WRITE` | `ONLINE`, `READ_WRITE`, primary |
| Availability groups | None | None |

Per table: rows, maximum identity value and `CHECKSUM_AGG(BINARY_CHECKSUM(*))`. Identical on both sides:

| Table | Rows | Max ID | Content checksum |
|---|---|---|---|
| `dbo.Course` | 4,007 | — | -2128299568 |
| `dbo.CourseAssignment` | 8,008 | — | 2128 |
| `dbo.Department` | 44 | 140 | -728795526 |
| `dbo.Enrollment` | 2,000,011 | 3,399,996 | -220432058 |
| `dbo.Notification` | 0 | — | — |
| `dbo.OfficeAssignment` | 2,003 | — | -102868175 |
| `dbo.Person` | 202,013 | 300,000 | 136859983 |

The MI's first full backup of `ContosoUniversity` after failover finished at 14:02:25.
