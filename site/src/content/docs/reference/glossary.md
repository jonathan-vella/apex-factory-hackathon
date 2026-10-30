---
title: Glossary
description: Terms used throughout the kit.
sidebar:
  order: 2
---

| Term | Meaning |
|---|---|
| ACR | Azure Container Registry: the private image registry used by C6 publishing and App Service. |
| ADR | Architecture decision record: a short note of a decision, an alternative you considered and the consequence. C4 produces them. |
| Agent mode | Copilot Chat mode that can use tools and change files with a person's review; distinct from selecting a custom agent such as Upgrade. |
| AHB | Azure Hybrid Benefit: eligible existing licenses reduce Azure license charges. Never claim it without eligible licenses. |
| ALZ | Azure Landing Zone: the governance and platform foundation for Azure workloads. ALZ-lite is this kit's smaller lab implementation. |
| ALZ-lite | This kit's scaled-down Azure Landing Zone: management groups, a hub, central policies and per-member vending, built for a two-day event rather than a production estate. |
| APEX | The agent-driven design tooling the CoE used to build the archetype. At the event an agent adapts the archetype to your tenant and documents it afterward; the APEX agents don't provision it. |
| APEX agent | A GitHub Copilot custom agent that ships in your repo (from `apex-accelerator`) and appears in Copilot Chat's agent picker, for example `01-Orchestrator`. |
| Arc, Azure Arc | The service that projects an on-premises (or lab) server and its SQL Server instance into Azure as a manageable resource, enabling the migration assessment and the MI link. |
| Archetype | The CoE's reference platform (App Service, ACR, SQL MI, Blob, Service Bus, Key Vault, Application Insights) that the modernized app runs on. |
| As-Built | Documentation of the deployed design, configuration and decisions. APEX produces the `07-*.md` documentation suite. |
| App Service | Azure's managed web hosting service. C7 runs the modernized Linux container here. |
| Application Insights | Application telemetry in Azure Monitor: requests, dependencies and failures exported by OpenTelemetry. Its connection string is endpoint metadata, not a credential when local authentication is disabled. |
| Azure CLI | The `az` command-line tool for Azure sign-in and resource operations. |
| Azure Firewall | The shared hub firewall that routes traffic between datacenter and spoke and forwards DNS queries. |
| Azure Monitor | Azure's monitoring platform, including Application Insights and Log Analytics. |
| `azd` | The Azure Developer CLI. In C5 you deploy the archetype with `azd provision`; it's the only tool that changes Azure for the archetype. |
| Bastion | Azure Bastion Standard in each datacenter. It's the only way into `vm-app01` and `vm-dev01`: the VMs have no public IPs, so you connect from the Azure portal in your browser. |
| Business outcome | A result the university wants, such as secure by default. [The customer story](../../getting-started/customer-story/) lists six, and each challenge page says which it serves. |
| CAF | Cloud Adoption Framework for Azure: guidance for cloud strategy, planning, readiness, adoption, governance and management. |
| CoE | Center of Excellence: the central team whose reference design the archetype is. |
| Copilot CLI | GitHub Copilot's terminal client; optional here, for the playbook's CLI path. |
| Corp management group | `mg-factory-corp`, the management group holding the team's workload subscriptions and their inherited policies. |
| CVE | Common Vulnerabilities and Exposures: a published identifier for a known vulnerability. C6 audits direct and transitive dependencies. |
| Cutover | The moment in C7 when the app switches from the source database on `vm-app01` to the managed instance, and the MI link is removed. |
| Datacenter | This kit's simulated on-premises environment: `vm-app01` (the legacy app and database) and `vm-dev01` (the member's workstation). |
| DeployIfNotExists | Azure Policy effect that deploys a missing related resource or setting, subject to its assignment identity and permissions. |
| Dev container | A ready-made Linux workspace that VS Code opens inside Docker, in your own repo (from `apex-accelerator`), with the Azure CLI, PowerShell 7, Git, `azd` and Bicep. You run the kit's scripts from `factory/` inside it. |
| DNS proxy | A DNS forwarder. The hub firewall forwards queries so standard Azure service host names resolve to private addresses. |
| Evidence folder | `factory/evidence/` in your own repo, set up in C1 from `factory/templates/team/evidence` (Step 3 already added `readiness/`). It holds written challenge evidence (`cNN/`) on `main`. In the dev container, run `git pull` first; on `vm-dev01`, use the plain clone and `git pull --rebase`. No code is deployed from it. |
| Event owner | The person coordinating the event: confirms each team's roster and member indexes, handles escalations from team leads, and owns cleanup. |
| Exemption | A recorded decision that a policy doesn't apply to a resource. The `vending` stage creates them for your datacenter when the team lead vends you at T-1, and you check them in C2. |
| Gate | A checkpoint you pass before you go on. T-14 and T-3 are gates before the event. In C3 the assessment gate and the plan gate are the points where you review the Upgrade agent's output before it continues. |
| GHCP | Abbreviation for GitHub Copilot, retained in existing URLs and older references. Titles use the full name. |
| Graph read grant | The Microsoft Graph read permission given to the SQL MI identity `id-sqlmi-directory`, so C7 can create the web app's database user. Someone with the Privileged Role Administrator role runs it once per team in Step 2 (T-7), right after the foundation. |
| Harness | Where the Upgrade agent runs. **Local** runs next to the app on `vm-dev01`; you pick it in Copilot Chat. |
| Hub | The team's shared virtual network `vnet-hub` in the shared services subscription, with Azure Firewall. Every member's spoke is peered to it. |
| Kit | This repository's content as you use it: the scripts, infrastructure, app, templates and archetype, imported into the `factory/` folder of your own repo. |
| Key Vault | Azure's secrets service. The app reads its database connection configuration using managed identity. |
| KPI | Key performance indicator: the measurable evidence that a business outcome was achieved. |
| Log Analytics | Azure Monitor's workspace for centralized logs; the foundation creates `log-management`. |
| Management group | A container above subscriptions that applies policy and access to everything inside it. ALZ-lite creates several and places your workload subscription under its Corp group. |
| Managed identity | An Azure-managed identity that obtains Entra tokens without an application password or key. |
| MCP | Model Context Protocol: the interface through which an agent can discover and call tool servers. |
| Member index | The number from 1 to 20 that the team lead assigns you. It sets your IP ranges and your peerings to the team's hub. Not the same as the suffix. Scripts and pages show it as `$s.memberIndex`, read from `factory/.local/settings.json`. |
| MI link | The managed instance link: a continuous, online replication path from an on-premises (or Arc-enabled) SQL Server to Azure SQL Managed Instance, used for the C7 migration. |
| MFA | Multifactor authentication: sign-in that requires more than one type of proof. |
| Microsoft Entra ID | The directory and identity service used for Azure sign-in, managed identities and database authentication. |
| MSMQ | Microsoft Message Queuing, the legacy notification transport replaced by Service Bus. |
| NAT gateway | Network address translation service for the datacenter VMs' outbound internet access; not an inbound access path. |
| NSG | Network security group: allow/deny rules applied to subnet or network-interface traffic. |
| OIDC | OpenID Connect: the federation protocol GitHub Actions uses to obtain Azure tokens without a stored client secret. |
| PIM | Privileged Identity Management. It grants an Azure or Entra role for a limited time after you activate it. If your Owner role is "eligible", activate it before you run preflight. |
| Platform lead | The name the workflow and the scripts use for the team lead. |
| Playbook | `.github/modernization/playbook.md`, the source of truth for the Upgrade agent's sequence, checks and recovery. |
| Preflight | The automated and manual checks you run before the event with the `whatif` stage of the platform pipeline. They are the first part of the readiness check. |
| Private endpoint | A private IP address in your virtual network for an Azure service, so traffic to it stays off the public internet. |
| Privileged Role Administrator | Microsoft Entra directory role used for the one-time SQL MI directory-read grant; different from Azure resource Owner. |
| Query Store | SQL Server's built-in record of query plans and run times. C9 uses it to show that each fix worked. |
| RBAC | Role-based access control: permissions granted to an identity at a defined scope. |
| Readiness check | The Step 3 checklist before the event that confirms your datacenter (`vm-app01` connected to Azure Arc) and `vm-dev01` are ready. It has no points and isn't a challenge. The Step 4 `vending` run checks each member's datacenter and Arc status automatically before vending their subscription. |
| Run command | An Azure feature that runs a script inside a VM without signing in to it. Arc onboarding turns it off for `vm-app01`, so the datacenter test must run before it (the `member` stage does). |
| Roster | The team lead's private `.local/roster.json`: member indexes and the values needed to vend each workload subscription. Never commit it. |
| Scenario | The kind of job the Upgrade agent runs. C3 uses `dotnet-version-upgrade`. |
| Service Bus | Azure's managed messaging service; the app uses the `notifications` queue with Entra authentication. |
| Shared services subscription | One subscription per team, held by the team lead, for the hub and shared management resources. |
| Spoke | A member's virtual network `vnet-spoke` in their workload subscription. Vending creates it and peers it to the hub. The archetype runs in it. |
| SQL MI | Azure SQL Managed Instance: the managed database service that replaces SQL Server on `vm-app01`. |
| SSMS | SQL Server Management Studio: the database management tool used for Query Store and SQL queries. |
| Storage / Blob Storage | Azure object storage. Teaching materials use the private `teaching-materials` container with Entra authentication. |
| Suffix | A random six-character string of lowercase letters and digits that `Initialize-Settings.ps1` generates once for you. It names your archetype resources, such as `rg-university-<suffix>`. Not the same as the member index. Scripts and pages show it as `$s.suffix`, read from `factory/.local/settings.json`. |
| T-14 | 14 days before day one of the event. Requirements, repo setup and preflight are due, and the team lead collects the roster values. |
| T-7 | 7 days before day one of the event. The team lead deploys the foundation and a Privileged Role Administrator runs the Graph read grant. |
| T-3 | 3 days before day one of the event. The readiness check is due: the datacenter, Arc onboarding, the first assessment and `vm-dev01` setup. See the [event overview](../../getting-started/event-overview/#before-the-event). |
| T-1 | 1 day before day one of the event. The team lead vends every member, restarts their VMs, records the exemptions and runs the connectivity probes. |
| T+2 | Two days after the event: preserve evidence, then remove member scopes, shared resources and pipeline access. |
| Tech lead | The person the event owner designates from the event delivery team—Microsoft, a partner or another third party—to give the 08:30 Day 1 kickoff. |
| Team lead | A colleague the team nominates and the team's first point of contact during pre-hackathon setup and the event. One per team, and also a member. Collects the roster values, assigns member indexes, deploys the foundation in Step 2 (T-7) and vends every member in Step 4 (T-1). |
| Tenant Root | The top management group of your Microsoft Entra tenant. The team lead needs Owner there or at the configured parent group. |
| Trace flag | A SQL Server startup switch that changes how the engine behaves. The kit sets two on the source (1800 and 9567) to prepare it for the MI link, and the assessment reports them as findings. |
| UDR | User-defined route: a routing rule on a subnet. Vending adds one that sends a member's traffic through the hub firewall. |
| Upgrade agent | GitHub Copilot's agent for assessing and executing a .NET upgrade, used in C3 and C6. |
| Vending | The per-member process of connecting a workload subscription into ALZ-lite's hub: placement under the Corp management group, spoke, subnets, peering, routes, DNS, firewall rules, RBAC and budget. |
| Workload subscription | One subscription per member for the datacenter, vended spoke and application archetype. |

## Where to go next

Start with [Requirements](../../getting-started/requirements/) if you haven't, then go to [Deploy](../../deploy/).
