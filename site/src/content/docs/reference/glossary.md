---
title: Glossary
description: Terms used throughout the kit.
---

| Term | Meaning |
|---|---|
| ALZ-lite | This kit's scaled-down Azure Landing Zone: management groups, a hub, central policies and per-member vending, built for a two-day event rather than a production estate. |
| APEX | The agent-driven deployment tooling this kit uses to adapt and provision the CoE archetype. |
| Archetype | The CoE's reference platform (App Service, SQL MI, Blob, Service Bus, Key Vault, Application Insights) that the modernized app runs on. |
| Arc, Azure Arc | The service that projects an on-premises (or lab) server and its SQL Server instance into Azure as a manageable resource, enabling the migration assessment and the MI link. |
| CoE | Center of Excellence — the team or pattern this kit's archetype represents. |
| Datacenter | This kit's simulated on-premises environment: `vm-app01` (the legacy app and database) and `vm-dev01` (the member's workstation). |
| GHCP | GitHub Copilot. |
| Lifeline | A coach-applied unblock for a stuck member or team, used at the coach's discretion — see your coach, not this glossary, for how it works. |
| MI link | The managed instance link: a continuous, online replication path from an on-premises (or Arc-enabled) SQL Server to Azure SQL Managed Instance, used for the C7 migration. |
| Preflight | The automated and manual readiness checks run before the event (`Test-Preflight.ps1`) and before day one (`Test-Datacenter.ps1`). |
| Upgrade agent | GitHub Copilot's agent for assessing and executing a .NET upgrade, used throughout C6. |
| Vending | The per-member process of connecting a workload subscription into ALZ-lite's hub: spoke, subnets, peering, routes, firewall rules and budget. |
