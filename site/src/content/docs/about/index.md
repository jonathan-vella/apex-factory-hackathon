---
title: About
description: Agenda, audience and feedback.
sidebar:
  label: Overview
  order: 0
---

The Partner Modernization Factory is a two-day hackathon, with pre-work, in which partner teams modernize one legacy app and its database on Azure with GitHub Copilot, Azure Arc and a CoE archetype built with APEX. The archetype is a Center of Excellence's reference design for the target platform, and APEX is the agent-driven tooling that built it. The [glossary](../reference/glossary/) explains the other terms.

## Audience

- Partner infrastructure architects and engineers. The application and database work is GitHub Copilot-assisted, so you don't need to be a .NET or SQL Server specialist.
- Teams of three to five. Each team has its own Microsoft Entra tenant and one platform lead, who is also a student. Each member has their own Azure workload subscription in that tenant.
- Partners bring their own paid Azure subscriptions and their own GitHub Copilot. Any paid subscription is supported; trial, Azure Pass and sponsorship subscriptions are not. Preflight doesn't check the offer type, so confirm in the Azure portal that yours is a paid subscription.
- Coaches are partner CoE leads or Microsoft partner solution architects. The event owner is the partner practice lead who runs the event.

See [Roles](../getting-started/roles/) for who does what, and [Prerequisites](../getting-started/prerequisites/) for what to have ready.

## Certifications

The event is hands-on first, and the exams come after it: infra roles hold AZ-104, GH-300 and DP-300 within six months after the event. No exam is a gate for attending the event. The [Partner learning path](../guides/learning-path/) has the details.

## Agenda

Pre-work comes first: [Prerequisites](../getting-started/prerequisites/) and C0's preflight by T-14 (14 days before day one), then by T-3 (3 days before day one) the datacenter is deployed, `Test-Datacenter.ps1` passes for you (run before Arc onboarding), `vm-app01` is connected to Azure Arc, your first migration assessment has run, the legacy app is healthy, and `vm-dev01` is set up with Copilot working in VS Code. The [event overview](../getting-started/event-overview/#pre-work) has both gates. The times below are the plan; your event owner may adjust them.

| Day 1 | Activity |
|---|---|
| 08:30 | Welcome, roles and roster lock |
| 09:00 | C1 Define the opportunity (the platform lead starts ALZ-lite first) |
| 09:45 | C2 Secure, AI-ready foundation, starting with a live portal ALZ demo |
| 10:15 | C3 Assess the source, in parallel with the platform lead's work in C2 |
| 11:45 | C4 Choose target states |
| 12:30 | Lunch |
| 13:15 | APEX archetype demo, then C5 Deploy the CoE archetype |
| 14:45 | C6 Modernize with GHCP, part 1 |
| 16:30 | Check-out |

| Day 2 | Activity |
|---|---|
| 08:30 | Reconnect and start the MI link |
| 09:00 | C6 Modernize with GHCP, part 2 |
| 10:30 | C7 Migrate and go live |
| 12:30 | Lunch |
| 13:15 | C8 Validate the pattern, then C9 Optimize the DB with GHCP |
| 15:15 | C10 Package, hand over, review AI readiness |
| 16:15 | Showcase, scoring and close, until 17:00 |

Challenge time boxes overlap in places, so they don't add up to the clock. Each is a guide for pacing, not a hard stop. The [challenges overview](../challenges/) has the minutes and points.

## Feedback

Tell your coach or the event owner what worked and what didn't during the event. To report a problem with the kit or suggest a change, open an issue in the [GitHub repository](https://github.com/jonathan-vella/apex-factory-hackathon/issues).

## Where to go next

Read [Roles](../getting-started/roles/), then start [Prerequisites](../getting-started/prerequisites/).
