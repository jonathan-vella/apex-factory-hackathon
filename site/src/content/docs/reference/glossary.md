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
| APEX | The agent-driven design tooling the CoE used to build the archetype. At the event an agent adapts the archetype to your tenant and documents it afterward; the APEX agents don't provision it. |
| APEX agent | A GitHub Copilot custom agent that ships in your repo (from `apex-accelerator`) and appears in Copilot Chat's agent picker, for example `01-Orchestrator`. |
| Arc, Azure Arc | The service that projects an on-premises (or lab) server and its SQL Server instance into Azure as a manageable resource, enabling the migration assessment and the MI link. |
| Archetype | The CoE's reference platform (App Service, ACR, SQL MI, Blob, Service Bus, Key Vault, Application Insights) that the modernized app runs on. |
| `azd` | The Azure Developer CLI. In C5 you deploy the archetype with `azd provision`; it's the only tool that changes Azure for the archetype. |
| Bastion | Azure Bastion Standard in each datacenter. It's the only way into `vm-app01` and `vm-dev01`: the VMs have no public IPs, so you connect from the Azure portal in your browser. |
| CoE | Center of Excellence: the central team whose reference design the archetype is. |
| Cutover | The moment in C7 when the app switches from the source database on `vm-app01` to the managed instance, and the MI link is removed. |
| Datacenter | This kit's simulated on-premises environment: `vm-app01` (the legacy app and database) and `vm-dev01` (the member's workstation). |
| Dev container | A ready-made Linux workspace that VS Code opens inside Docker, in your own repo (from `apex-accelerator`), with the Azure CLI, PowerShell 7, Git, `azd` and Bicep. You run the kit's scripts from `factory/` inside it. |
| Evidence folder | `factory/evidence/` in your own repo, created in C1 from `factory/templates/team/evidence`. It holds your written evidence for each challenge (`cNN/`), committed to `main`. In the dev container, run `git pull` first. On `vm-dev01`, use `C:\src\<your-repo>\factory\evidence\` and run `git pull --rebase` first. No code is deployed from it. |
| Exemption | A recorded decision that a policy doesn't apply to a resource. `New-DatacenterExemptions.ps1` creates them for your datacenter when the platform lead vends you at T-1, and you check them in C2. |
| Gate | A checkpoint you pass before you go on. T-14 and T-3 are gates before the event. In C3 the assessment gate and the plan gate are the points where you review the Upgrade agent's output before it continues. |
| GHCP | GitHub Copilot, as written in challenge titles. |
| Graph read grant | The Microsoft Graph read permission given to the SQL MI identity `id-sqlmi-directory`, so C7 can create the web app's database user. Someone with the Privileged Role Administrator role runs it once per team at T-7, right after ALZ-lite, and the team checks it in C2. |
| Harness | Where the Upgrade agent runs. **Local** runs next to the app on `vm-dev01`; you pick it in Copilot Chat. |
| Hub | The team's shared virtual network `vnet-hub` in the shared services subscription, with Azure Firewall. Every member's spoke is peered to it. |
| Kit | This repository's content as you use it: the scripts, infrastructure, app, templates and archetype, imported into the `factory/` folder of your own repo. |
| Lifeline | A coach-applied unblock for a stuck member or team, used at the coach's discretion. Ask your coach, not this glossary, how it works. |
| Management group | A container above subscriptions that applies policy and access to everything inside it. ALZ-lite creates several and places your workload subscription under its Corp group. |
| Member index | The number from 1 to 20 your coach assigns you. It sets your IP ranges and your peerings to the team's hub. Not the same as the suffix. Scripts and pages show it as `$s.memberIndex`, read from `factory/.local/settings.json`. |
| MI link | The managed instance link: a continuous, online replication path from an on-premises (or Arc-enabled) SQL Server to Azure SQL Managed Instance, used for the C7 migration. |
| PIM | Privileged Identity Management. It grants an Azure or Entra role for a limited time after you activate it. If your Owner role is "eligible", activate it before you run preflight. |
| Platform lead | The one person per team who deploys ALZ-lite at T-7 and vends every member's subscription at T-1, then walks the team through both in C2. The platform lead is also a student and does every member challenge. |
| Preflight | The automated and manual readiness checks you run before the event with `Test-Preflight.ps1`. `Test-Datacenter.ps1` is a separate check of the deployed datacenter. |
| Private endpoint | A private IP address in your virtual network for an Azure service, so traffic to it stays off the public internet. |
| Query Store | SQL Server's built-in record of query plans and run times. C9 uses it to show that each fix worked. |
| Run command | An Azure feature that runs a script inside a VM without signing in to it. Arc onboarding turns it off for `vm-app01`, so `Test-Datacenter.ps1` must run before it. |
| Scenario | The kind of job the Upgrade agent runs. C3 uses `dotnet-version-upgrade`. |
| Spoke | A member's virtual network `vnet-spoke` in their workload subscription. Vending creates it and peers it to the hub. The archetype runs in it. |
| SQL MI | Azure SQL Managed Instance: the managed database service that replaces SQL Server on `vm-app01`. |
| Suffix | A random six-character string of lowercase letters and digits that `Initialize-Settings.ps1` generates once for you. It names your archetype resources, such as `rg-university-<suffix>`. Not the same as the member index. Scripts and pages show it as `$s.suffix`, read from `factory/.local/settings.json`. |
| T-14 | 14 days before day one of the event. Prerequisites and C0's preflight are due, and the event owner captures the roster values. |
| T-7 | 7 days before day one of the event. The platform lead deploys ALZ-lite and a Privileged Role Administrator runs the Graph read grant. |
| T-3 | 3 days before day one of the event. The datacenter, Arc onboarding, the first assessment and `vm-dev01` setup are due. See the [event overview](../../getting-started/event-overview/#pre-work). |
| T-1 | 1 day before day one of the event. The platform lead vends every member, restarts their VMs, records the exemptions and runs the connectivity probes. |
| Tenant Root | The top management group of your Microsoft Entra tenant. The platform lead needs the Owner role there. |
| Trace flag | A SQL Server startup switch that changes how the engine behaves. The kit sets two on the source (1800 and 9567) to prepare it for the MI link, and the assessment reports them as findings. |
| UDR | User-defined route: a routing rule on a subnet. Vending adds one that sends a member's traffic through the hub firewall. |
| Upgrade agent | GitHub Copilot's agent for assessing and executing a .NET upgrade, used in C3 and C6. |
| Vending | The per-member process of connecting a workload subscription into ALZ-lite's hub: placement under the Corp management group, spoke, subnets, peering, routes, DNS, firewall rules, RBAC and budget. |

## Where to go next

Start with [Prerequisites](../../getting-started/prerequisites/) if you haven't, then [C0: Ready to hack](../../challenges/c00-ready-to-hack/).
