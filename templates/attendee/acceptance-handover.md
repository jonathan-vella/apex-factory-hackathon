# Acceptance and handover

<!--
Used in C8 (per member, against the acceptance pack) and C10 (rolled up for the whole team). Record every check's actual result (pass, fail or not applicable), not an expected one.
-->

Member index: <!-- your member number, 1 to 20 -->

## Smoke checks

<!-- C8 task 1: the five pages in a browser, and the row-count query run against the source and the managed instance (paste both results). -->

| Check | Result | Evidence |
|---|---|---|
| Home page (`GET /`) loads | | |
| Students page loads with data | | |
| Courses page loads with data | | |
| Instructors page loads with data | | |
| Departments page loads with data | | |
| Row counts match the source (students, instructors, courses, departments, enrollments) | | |

## Upload round-trip (private endpoint)

| Check | Result | Evidence |
|---|---|---|
| Upload an image on Courses > Edit | | |
| Image shows on the course | | |
| Blob appears in `teaching-materials` (`az storage blob list` on vm-dev01) | | |
| Replace the image | | |
| Delete the image | | |
| Non-image file rejected | | |
| File over 5 MB rejected | | |

## Notification round-trip (private endpoint)

<!-- C8 task 3: evidence is the Network panel's GetNotifications response (status 200, success true, count 1 or more) and the toast. -->

| Check | Result | Evidence |
|---|---|---|
| Edit a student | | |
| Toast appears within 5 seconds | | |
| `/Notifications/GetNotifications` returns success | | |

## Load check

| Check | Result | Evidence |
|---|---|---|
| App stays healthy under a short burst of concurrent page loads (every response 200) | | |

## Security check

<!-- C8 task 5: attach Test-Acceptance.ps1's output (acceptance.json). Policy and Defender views are corroboration only. -->

| Check | Result | Evidence |
|---|---|---|
| `Test-Acceptance.ps1` verdict is ACCEPT | | |
| HTTP redirects to HTTPS | | |
| Web app HTTPS-only | | |
| Web app minimum TLS 1.2 | | |
| SQL MI public data endpoint disabled | | |
| Blob Storage public network access disabled, approved private endpoint | | |
| Service Bus public network access disabled, approved private endpoint | | |
| Key Vault public network access disabled, approved private endpoint | | |
| ACR public network access disabled, approved private endpoint | | |

## Telemetry

<!-- C8 evidence: Application Insights > Investigate > Transaction search, time range the last 30 minutes, with the requests and dependencies from your checks. -->

| Check | Result | Evidence |
|---|---|---|
| Requests and dependencies from this session's checks visible in Application Insights | | |

## Handover summary (C10)

<!-- What's being handed over, to whom, and what they need to know to operate it without the team in the room. Cover every member: list each member index and link to their C8 pack in evidence/c08/member-<n>/. -->
