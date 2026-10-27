# Acceptance and handover

<!--
Used in C8 (per member, against the acceptance pack) and C10 (rolled up for the whole team). Record every check's actual result (pass, fail or not applicable), not an expected one. The acceptance pack is this filled-in document plus the evidence files beside it.
-->

Member index: <!-- your member number, 1 to 20; in C10, leave it blank and use the table in the handover summary -->

## Smoke checks

<!-- C8 requirement 1: the five pages in a browser, and the row-count query run against the source and the managed instance (paste both results). -->

| Check | Result | Evidence |
|---|---|---|
| Home page (`GET /`) loads | | |
| Students page loads with data | | |
| Courses page loads with data | | |
| Instructors page loads with data | | |
| Departments page loads with data | | |
| Row counts match the source (students, instructors, courses, departments, enrollments) | | |

## Upload round-trip (private endpoint)

<!-- C8 requirement 2: use a throwaway course (Courses > Create New, course ID 9901). The app has no separate "delete image" control, so the image is removed by deleting that course. Never delete a seeded course. -->

| Check | Result | Evidence |
|---|---|---|
| Create a throwaway course with an image | | |
| Image shows on the course | | |
| Blob appears in `teaching-materials` (`az storage blob list` on vm-dev01) | | |
| Replace the image on the course's Edit page; the blob changes | | |
| Delete the throwaway course; its blob is gone | | |
| Non-image file rejected | | |
| File over 5 MB rejected | | |

## Notification round-trip (private endpoint)

<!-- C8 requirement 3: evidence is the Network panel's GetNotifications response (status 200, success true, count 1 or more) and the toast. -->

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

<!-- C8 requirement 5: attach Test-Acceptance.ps1's output (acceptance.json). Policy and Defender views are corroboration only. An UNKNOWN keeps the verdict at NOT ACCEPTED: settle it in the portal, add the screenshot as evidence, and note it in the row. -->

| Check | Result | Evidence |
|---|---|---|
| `Test-Acceptance.ps1` verdict is ACCEPT (or each UNKNOWN is settled in the portal) | | |
| HTTP redirects to HTTPS | | |
| Web app HTTPS-only | | |
| Web app minimum TLS 1.2 | | |
| SQL MI public data endpoint disabled | | |
| Blob Storage public network access disabled, approved private endpoint | | |
| Service Bus public network access disabled, approved private endpoint | | |
| Key Vault public network access disabled, approved private endpoint | | |
| ACR public network access disabled, approved private endpoint | | |

## Telemetry

<!-- C8 requirement 6: Application Insights (appi-university-<suffix>) > Investigate > Transaction search, time range the last 30 minutes, with the requests and dependencies from your checks. -->

| Check | Result | Evidence |
|---|---|---|
| Requests and dependencies from this session's checks visible in Application Insights | | |

## Handover summary (C10)

<!-- C10 only. What's being handed over, to whom, and what they need to know to operate it without the team in the room. Copy each member's C8 pack into factory/evidence/c10/member-packs/ and link it here. -->

| Member | Member index | C8 pack | Result (ACCEPT or NOT ACCEPTED) |
|---|---|---|---|
| | | | |

Handed over to:

How to operate it:
