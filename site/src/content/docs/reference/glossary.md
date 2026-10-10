---
title: Glossary
description: Terms used throughout the kit.
sidebar:
  order: 5
---

| Term | Meaning |
|---|---|
| ADR | Architecture decision record: a short note of a decision, an alternative you considered and the consequence. C4 produces them. |
| ALZ-lite | This kit's scaled-down Azure Landing Zone: management groups, a hub, central policies and per-member vending, built for a two-day event rather than a production estate. |
| APEX | The agent-driven design tooling the CoE used to build the archetype. At the event an agent adapts the archetype to your tenant and documents it afterwards; the APEX agents don't provision it. |
| Archetype | The CoE's reference platform (App Service, ACR, SQL MI, Blob, Service Bus, Key Vault, Application Insights) that the modernized app runs on. |
| Arc, Azure Arc | The service that projects an on-premises (or lab) server and its SQL Server instance into Azure as a manageable resource, enabling the migration assessment and the MI link. |
| `azd` | The Azure Developer CLI. In C5 you deploy the archetype with `azd provision`; it's the only tool that changes Azure for the archetype. |
| Bastion | Azure Bastion Standard in each datacenter. It's the only way into `vm-app01` and `vm-dev01`: the VMs have no public IPs. |
| CoE | Center of Excellence: the team or pattern this kit's archetype represents. |
| Datacenter | This kit's simulated on-premises environment: `vm-app01` (the legacy app and database) and `vm-dev01` (the member's workstation). |
| Dev container | The containerized development environment in your own repo (from `apex-accelerator`) with the Azure CLI, PowerShell 7, Git, `azd` and Bicep. You run the kit's scripts from `factory/` inside it. |
| GHCP | GitHub Copilot. |
| Kit | This repository's content as you use it: the scripts, infrastructure, app, templates and archetype, imported into the `factory/` folder of your own repo. |
| Lifeline | A coach-applied unblock for a stuck member or team, used at the coach's discretion — see your coach, not this glossary, for how it works. |
| Member index | The number from 1 to 20 your coach assigns you. It sets your IP ranges and your peerings to the team's hub. Not the same as the suffix. |
| MI link | The managed instance link: a continuous, online replication path from an on-premises (or Arc-enabled) SQL Server to Azure SQL Managed Instance, used for the C7 migration. |
| Platform lead | The one person per team who deploys ALZ-lite and vends every member's subscription in C2. The platform lead is also a student and does every member challenge. |
| Preflight | The automated and manual readiness checks you run before the event with `Test-Preflight.ps1`. `Test-Datacenter.ps1` is a separate check of the deployed datacenter. |
| Spoke | A member's virtual network `vnet-spoke` in their workload subscription. Vending creates it and peers it to the hub. The archetype runs in it. |
| Suffix | A random six-character string that `Initialize-Settings.ps1` generates once for you. It names your archetype resources, such as `rg-university-<suffix>`. Not the same as the member index. |
| Team repo | The one private repo your whole team shares, created in C1 from `templates/team/`. It holds the team's written evidence, and no code is deployed from it. |
| Upgrade agent | GitHub Copilot's agent for assessing and executing a .NET upgrade, used throughout C6. |
| Vending | The per-member process of connecting a workload subscription into ALZ-lite's hub: placement under the Corp management group, spoke, subnets, peering, routes, DNS, firewall rules, RBAC and budget. |
