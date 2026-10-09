# Acceptance and handover

<!--
Used in C8 (per member, against the acceptance pack) and C10 (rolled up for the whole team). Record every check's actual result, not an expected one.
-->

## Smoke checks

| Check | Result | Evidence |
|---|---|---|
| Home page loads | | |
| Students page loads with data | | |
| Courses page loads with data | | |
| Instructors page loads with data | | |
| Departments page loads with data | | |

## Upload round-trip (private endpoint)

| Check | Result | Evidence |
|---|---|---|
| Upload an image on Courses > Edit | | |
| Image shows on the course | | |
| Replace the image | | |
| Delete the image | | |
| Non-image file rejected | | |
| Over-size file rejected | | |

## Notification round-trip (private endpoint)

| Check | Result | Evidence |
|---|---|---|
| Edit a student | | |
| Toast appears within 5 seconds | | |
| `/Notifications/GetNotifications` returns success | | |

## Load check

| Check | Result | Evidence |
|---|---|---|
| App stays healthy under a short burst of concurrent page loads | | |

## Security check

| Check | Result | Evidence |
|---|---|---|
| SQL MI public data endpoint disabled | | |
| Blob Storage public network access disabled | | |
| Service Bus public network access disabled | | |
| Key Vault public network access disabled | | |
| ACR public network access disabled | | |
| Web app HTTPS-only, TLS 1.2 minimum | | |

## Handover summary (C10)

<!-- What's being handed over, to whom, and what they need to know to operate it without the team in the room. -->
