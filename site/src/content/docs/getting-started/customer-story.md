---
title: The customer story
description: Who Contoso University is, why it has to change and what its leaders want from your team.
sidebar:
  order: 1
---

Contoso University is fictional. The app, its setup and the Azure services in this kit are real. The size, the history and the people below are the scenario. Nothing here was measured, and every target is illustrative.

## Who they are

Contoso University is a public university with about 25,000 students and several faculties. A small central IT team keeps the campus systems running. The registrar's office runs enrollment on a web app the university has used for years. It holds students, courses, instructors, departments and enrollments. Instructors upload teaching materials to their courses, and staff see a notification when a record changes.

## Where they are coming from

The app is ASP.NET MVC 5 on .NET Framework 4.8. It runs in IIS on a Windows virtual machine in the university's own datacenter, with SQL Server beside it. Uploaded files sit on the VM's disk, and notifications travel through MSMQ, a Windows message queue. The database password is written into the app's configuration file. The IT team patches the VM by hand and deploys by copying files.

The vendor that built the app no longer supports it. A recent audit flagged the platform and the way the app stores its database password.

## Why they have to change

Risk comes first. The app ties the university to a Windows VM that someone must patch by hand, and its secrets sit in a file. A failed patch or a leaked file puts enrollment at risk.

AI readiness comes second. The registrar wants to analyze enrollment data. The old stack has no safe, governed place to do that.

## Who you work for

You are the delivery team of a Microsoft partner. The university has hired your partner to modernize the app and to leave behind a pattern its own team can repeat. Four people speak for the university.

| Role | Name | What they care about |
| --- | --- | --- |
| CIO | Dana | A platform with a future, and a plan the board can follow |
| Registrar | Marcus | Enrollment weeks that work, and a short, planned stop when the app moves |
| Head of IT operations | Priya | Less hand patching, and changes she can repeat and roll back |
| Security lead | Tomás | No stored secrets, no public data endpoints, and proof of both |

## What the business wants

The university wants six outcomes. Each challenge serves one or more, and each challenge page says which. Your team ranks them in [C1](../../challenges/c01-define-the-opportunity/).

| Outcome | What it means |
| --- | --- |
| Current platform | The app runs on a current .NET and Azure platform that the vendor and Microsoft support |
| Secure by default | No stored passwords or keys, no public data endpoints, and access through identity |
| Safe, repeatable change | Risks are known before work starts, the cutover is planned, and a rollback is written down |
| Repeatable provisioning | The platform is deployed from code and documented as built |
| Reliable at enrollment peaks | Slow queries are found and fixed, with numbers before and after |
| Documented path to AI | The team records what is ready for AI use and what is not, with owners |

Illustrative target, to give the ranking something to aim at: the registrar's office stops for under an hour at cutover. Your team writes its own measures in C1.

## What you leave behind

A working app on Azure, evidence for each outcome, and a package another team can pick up without you in the room.

<details>
<summary>What is in the repo and what is scenario</summary>

In the repo, and true in the lab:

- The app is ASP.NET MVC 5 on .NET Framework 4.8, on IIS in a Windows VM, with SQL Server on the same VM.
- It manages students, courses, instructors, departments and enrollments.
- Course teaching materials are saved to local disk.
- Notifications use MSMQ.
- The deployed lab app connects with a SQL login whose password is written into its configuration file. The source copy of the file points at LocalDB.
- There is no deployment pipeline.

Part of the scenario, not a measurement:

- The university is public, with about 25,000 students.
- The IT team is small and patches by hand.
- The vendor no longer supports the app.
- A recent audit raised the platform and the password storage.
- The registrar wants analytics on enrollment data.
- Dana, Marcus, Priya and Tomás.

</details>
