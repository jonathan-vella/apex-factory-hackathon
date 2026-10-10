---
title: Partner learning path
description: Learning before the event, certifications after it, and how both support the Partner Center specializations.
sidebar:
  order: 5
---

This page links each factory challenge to Microsoft Learn content and to the credential that builds on it. It also shows which role takes which exam, and in what order. The event is hands-on first: you learn a little before it, build the factory, and take the exams afterwards.

:::note
This page is a plan. No exam is a gate for attending the event. Exam rules, outlines and Partner Center requirements change. The links go to the pages that are the source of truth. [Last validated](#last-validated) shows when each one was checked.
:::

## Who it's for

- Microsoft partners, mostly infrastructure architects and engineers. The app and database work in the factory is Copilot-assisted.
- Any partner. Nothing here depends on your Solutions Partner qualification track. Where a designation gate counts certified people, plan for two per gate. That covers every track.
- Everyone in an infra role (platform lead, workload engineer, security engineer) holds all three core certifications: AZ-104, GH-300 and DP-300.
- Applied Skills are recommended stepping stones. They're never gates.
- Coaches: GH-300 plus DP-300 or AZ-104 is recommended, not required.

The role tracks below are about certifications. For who does what during the event, see [Roles](../../getting-started/roles/).

## Stages

| Stage | When | Goal | Content | Exit evidence |
| --- | --- | --- | --- | --- |
| 0 Ready | T-30 to T-3 | Learning only. No exam gates. | The [AZ-104 course](https://learn.microsoft.com/training/courses/az-104t00) (start with its networking, identity and governance modules); [GitHub Copilot Fundamentals Part 1](https://learn.microsoft.com/training/paths/copilot/); the [Arc SQL migration assessment](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment) docs; the [GH-900 study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-900) (optional); the Applied Skill [Accelerate AI-assisted development by using GitHub Copilot](https://learn.microsoft.com/credentials/applied-skills/accelerate-app-development-by-using-github-copilot/) (recommended) | The paths show as complete on your Learn profile |
| 1 Hack | T-0 | Build the factory | The [challenges](../../challenges/), C0 to C10 | Your coach signs off each challenge's evidence |
| 2 Certify core | Within 6 months after the event (T+0 to T+180 days) | Hold the core certifications | [AZ-104](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-104), [GH-300](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-300) and [DP-300](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-300): all three for every infra role. Data and developer roles take their core exams from the [role tracks](#role-tracks). Data roles also take [DP-800](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-800), which Infra and Database Migration requires | Passed exams on your Learn profile |
| 3 Specialize | Months 6 to 9 after the event (T+180 to T+270 days) | Add depth in design, DevOps, security and networking | [AZ-305](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-305), [AZ-400](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-400), [SC-500](https://learn.microsoft.com/credentials/certifications/resources/study-guides/sc-500) and [AZ-700](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-700); [AI-200](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-200) for the developer track; the [AKS (AZ-1001)](https://learn.microsoft.com/training/paths/deploy-manage-containers-azure-kubernetes-service/) and [Azure Container Apps (AZ-2003)](https://learn.microsoft.com/training/paths/deploy-cloud-native-applications-to-azure-container-apps/) learning paths | Passed exams on your Learn profile; both paths complete |
| 4 Next (optional) | Within the 9 months | Prepare for the [Enable AI tomorrow](#next-enable-ai-tomorrow) follow-on | [GH-600](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-600) and [AI-103](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-103) | Passed exams on your Learn profile |

Four things to know:

- C0 is pre-work, not learning. It's separate from Stage 0: see [Pre-work](../../getting-started/pre-work/).
- AZ-400 needs AZ-104 or the Azure Developer Associate certification first. AZ-204 retired, and AI-200 isn't listed as a prerequisite, so route infra people through AZ-104.
- AKS and Container Apps are learning content, not a kit path. The factory runs on App Service only.
- Link to the study guides and don't copy their skills lists: the outlines change.

## Role tracks

| Role | Core | Specialize | Next | Challenges |
| --- | --- | --- | --- | --- |
| Platform lead (infra) | AZ-104, GH-300, DP-300 | AZ-700, AZ-305, SC-500 | None | C2, C5, C8 |
| Workload engineer (infra) | AZ-104, GH-300, DP-300 | AZ-400; AKS and Container Apps paths | GH-600 | C3, C5, C6, C7, C8, C9 |
| Security engineer (infra) | AZ-104, GH-300, DP-300 | SC-500 | None | C2, C8 |
| Data or database specialist | DP-300, DP-800 | SC-500 or AZ-104 | None | C3, C4, C7, C9 |
| App modernization developer | GH-300 | AI-200; AZ-400 (after AZ-104); AKS and Container Apps paths | GH-600, AI-103 | C6, C8 |
| Coach or CoE lead | Recommended: GH-300 plus DP-300 or AZ-104 | AZ-305 | GH-600 | All, as coach |
| Practice lead | No exam needed | AZ-305 (optional) | None | Runs the event |

DP-800 is the extra group that Infra and Database Migration requires, so a team needs at least one DP-800 holder. The data specialist takes it. AI-200 is Python-oriented and covers Cosmos DB, PostgreSQL vectors and Redis, so it stays on the developer track.

## Challenge map

Each row links to the challenge, lists the skills it exercises and points to Learn content. The last column is the credential that validates those skills.

| Challenge | Skills exercised | Learn | Credential |
| --- | --- | --- | --- |
| [C0: Ready to hack](../../challenges/c00-ready-to-hack/) | Subscription readiness, Azure Arc onboarding, first SQL migration assessment | [Azure Arc hybrid path](https://learn.microsoft.com/training/paths/manage-hybrid-infrastructure-with-azure-arc/); [Arc SQL migration assessment](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment) | AZ-104, GH-300 |
| [C1: Define the opportunity](../../challenges/c01-define-the-opportunity/) | Scoping a modernization opportunity and a plan | [Cloud Adoption Framework strategy](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/); [Well-Architected Framework path](https://learn.microsoft.com/training/paths/azure-well-architected-framework/) | AZ-305 |
| [C2: Secure, AI-ready foundation](../../challenges/c02-secure-ai-ready-foundation/) | Landing zone, management groups, policy, RBAC, hub and spoke networking, private DNS | [AZ-104 identities and governance](https://learn.microsoft.com/training/paths/az-104-manage-identities-governance/); [AZ-700 networking path](https://learn.microsoft.com/training/paths/design-implement-microsoft-azure-networking-solutions-az-700/); [Azure landing zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) | AZ-104, AZ-700, SC-500, AZ-305 |
| [C3: Assess the source](../../challenges/c03-assess-the-source/) | Reviewing migration assessment findings, SQL Managed Instance compatibility | [Migrate SQL Server workloads to Azure SQL](https://learn.microsoft.com/training/paths/migrate-sql-workloads-azure/); [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation) | DP-300, GH-300 |
| [C4: Choose target states](../../challenges/c04-choose-target-states/) | Architecture decisions, migration method, deferred work | [Architect migration, BCDR and disaster recovery](https://learn.microsoft.com/training/paths/architect-migration-bcdr/); [Choose a migration tool for SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-overview) | AZ-305, DP-300 |
| [C5: Deploy the CoE archetype](../../challenges/c05-deploy-the-coe-archetype/) | Infrastructure as code, `azd`, App Service, registry, SQL Managed Instance, Key Vault, agent-assisted deployment | [AZ-104 compute resources](https://learn.microsoft.com/training/paths/az-104-manage-compute-resources/); [Azure Developer CLI overview](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview) | AZ-104, DP-300, GH-600 |
| [C6: Modernize with GHCP](../../challenges/c06-modernize-with-ghcp/) | .NET upgrade with Copilot, managed identity, Blob, Service Bus, container image | [GitHub Copilot Fundamentals Part 2](https://learn.microsoft.com/training/paths/gh-copilot-2/); [Modernize ASP.NET Framework to ASP.NET Core](https://learn.microsoft.com/training/modules/modernize-aspnet-framework-to-core/); the [Applied Skill](https://learn.microsoft.com/credentials/applied-skills/accelerate-app-development-by-using-github-copilot/) | GH-300 (AI-200 for the developer track) |
| [C7: Migrate and go live](../../challenges/c07-migrate-and-go-live/) | Managed Instance link, replica validation, cutover, App Service go-live | [Migrate with the Managed Instance link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-migrate); [Migrate to SQL Managed Instance with Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/migrate-to-azure-sql-managed-instance) | DP-300 |
| [C8: Validate the pattern](../../challenges/c08-validate-the-pattern/) | Acceptance checks, private endpoints, identity, monitoring | [AZ-104 monitor and back up](https://learn.microsoft.com/training/paths/az-104-monitor-backup-resources/); [Monitor App Service](https://learn.microsoft.com/azure/app-service/monitor-app-service); [Private endpoints for Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints) | SC-500, AZ-104 |
| [C9: Optimize the DB with GHCP](../../challenges/c09-optimize-the-db-with-ghcp/) | Query Store, query tuning, Copilot-assisted database changes | [Optimize query performance in Azure SQL](https://learn.microsoft.com/training/paths/optimize-query-performance-sql-server/); [Query Store overview](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store) | DP-300, DP-800 |
| [C10: Package, hand over, review AI readiness](../../challenges/c10-package-hand-over-review-ai-readiness/) | Reusable asset, handover, AI-readiness review | [Cloud Adoption Framework: govern](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/); [Introduction to AI landing zones](https://learn.microsoft.com/training/modules/intro-ai-landing-zones/) | AZ-305, GH-600 |
| Beyond v1: AKS and Container Apps | The same container on AKS or Container Apps | The [AKS](https://learn.microsoft.com/training/paths/deploy-manage-containers-azure-kubernetes-service/) and [Container Apps](https://learn.microsoft.com/training/paths/deploy-cloud-native-applications-to-azure-container-apps/) paths | AI-200, SC-500, AZ-104 |

### Badges and exam domains

Each factory badge maps to the exam domain that validates the same skill. Domain names come from the study guides on the [last validated](#last-validated) date.

| Badge | Exam domain |
| --- | --- |
| Zero public backend endpoints | AZ-700: Design and implement private access to Azure services. SC-500: Secure storage, databases, and networking |
| Policy clean | AZ-104: Manage Azure identities and governance |
| Rollback ready | DP-300: Plan and configure a high availability and disaster recovery (HA/DR) environment. AZ-305: Design business continuity solutions |
| Trust but verify | GH-300: Use GitHub Copilot responsibly |
| Cost guardian | AZ-104: Manage Azure identities and governance, which includes cost alerts and budgets |
| Reusable-asset contributor | AZ-400: Design and implement build and release pipelines, the closest fit |

## Partner Center outcomes

The factory supports two Partner Center specializations. Each one needs an active Solutions Partner designation, and each lists the certifications your people must hold. Both also have revenue and audit requirements that this page doesn't cover.

| Specialization | Required designation | Skilling |
| --- | --- | --- |
| [Infra and Database Migration to Microsoft Azure](https://partner.microsoft.com/en-us/partnership/specialization/infra-and-database-migration) | Data & AI (Azure) or Infrastructure (Azure) | Four or more people, with at least one certification from each group: DevOps Engineer Expert (AZ-400); Azure Administrator Associate (AZ-104); Cloud and AI Security Engineer Associate (SC-500); Azure Database Administrator Associate (DP-300); SQL AI Developer Associate (DP-800) |
| [App Modernization on Microsoft Azure](https://partner.microsoft.com/en-us/partnership/specialization/app-modernization-on-microsoft-azure) | Data & AI (Azure) or Digital & App Innovation (Azure) | Three or more people, with at least one certification from each group: DevOps Engineer Expert (AZ-400); Azure AI Cloud Developer Associate (AI-200) or the retired Azure Developer Associate; Azure Administrator Associate (AZ-104) |

DP-800 is a required group for Infra and Database Migration, in addition to DP-300. The partner page lists SQL AI Developer Associate (DP-800) as a fifth group, and this plan treats it that way.

### Sample plan for five people

A team of five can cover both specializations:

| Person | Exams |
| --- | --- |
| Platform lead | AZ-104, GH-300, DP-300, AZ-305, AZ-700 |
| DevOps | AZ-104, GH-300, DP-300, AZ-400 |
| Data | DP-300, DP-800 |
| Security | AZ-104, GH-300, DP-300, SC-500 |
| Developer | AI-200 |

Infra and Database Migration needs four or more people across five groups. The platform lead, DevOps, data and security people cover them: AZ-400 (DevOps), AZ-104 (platform lead), SC-500 (security), DP-300 (platform lead) and DP-800 (data). App Modernization needs three or more people across three groups. The DevOps, developer and platform lead people cover them: AZ-400, AI-200 and AZ-104. Every group in both tables has a holder.

### Designation gates

The Solutions Partner designation pages count certified people per gate. Plan for two AZ-104 holders and two AZ-305 holders, which covers every qualification track. The sample plan has three AZ-104 holders and one AZ-305 holder, so the coach or CoE lead should be the second AZ-305 holder. The Infrastructure designation takes the Azure Network Engineer Associate certification (AZ-700) for its second step. See [Solutions Partner for Data & AI, Infrastructure, and Digital & App Innovation](https://learn.microsoft.com/partner-center/membership/solutions-partner-azure).

Requirements change. Partner Center is the source of truth.

### Retired exams

Don't plan for the exams below. A certification earned before it retired still counts for Partner Center for one year after the retirement date, per [Exam and assessment lab retirement](https://learn.microsoft.com/credentials/support/retired-certification-exams).

| Retired exam | Retired on | Use instead |
| --- | --- | --- |
| AZ-204 | July 31, 2026 | AI-200 |
| AZ-500 | August 31, 2026 | SC-500 |
| AI-102 | June 30, 2026 | AI-103 |
| AZ-800 and AZ-801 | September 30, 2026 | AZ-700, for Infrastructure points |

## Next: Enable AI tomorrow

This stage is optional. It prepares your people for the "Enable AI tomorrow" follow-on, and none of it is a gate.

| Exam | Certification | Fits |
| --- | --- | --- |
| [GH-600](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-600) | [GitHub Certified: Agentic AI Developer](https://learn.microsoft.com/credentials/certifications/agentic-ai-developer/) | Workload engineers, developers and coaches who work with the APEX agents |
| [AI-103](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-103) | Azure AI Apps and Agents Developer Associate | Developers. It replaces AI-102 |

## Last validated

**October 10, 2026.** On that date every link on this page was opened, each exam's study guide was read, the retirement page was checked, and both specialization pages and the designation page were compared with this plan.

| Exam | Certification | Status | Skills outline date |
| --- | --- | --- | --- |
| [AZ-104](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-104) | Azure Administrator Associate | Active | April 17, 2026 |
| [GH-300](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-300) | GitHub Copilot | Active | August 7, 2026 |
| [DP-300](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-300) | Azure Database Administrator Associate | Active | October 27, 2026 (update not yet live) |
| [AZ-305](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-305) | Azure Solutions Architect Expert | Active | April 17, 2026 |
| [AZ-400](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-400) | DevOps Engineer Expert | Active | July 27, 2026 |
| [SC-500](https://learn.microsoft.com/credentials/certifications/resources/study-guides/sc-500) | Cloud and AI Security Engineer Associate | Active | Not shown |
| [AZ-700](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-700) | Azure Network Engineer Associate | Active | July 27, 2026 |
| [AI-200](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-200) | Azure AI Cloud Developer Associate | Active | Not shown |
| [DP-800](https://learn.microsoft.com/credentials/certifications/resources/study-guides/dp-800) | SQL AI Developer Associate | Active | October 19, 2026 (update not yet live) |
| [GH-600](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-600) | [GitHub Certified: Agentic AI Developer](https://learn.microsoft.com/credentials/certifications/agentic-ai-developer/) | Active | Not shown |
| [AI-103](https://learn.microsoft.com/credentials/certifications/resources/study-guides/ai-103) | Azure AI Apps and Agents Developer Associate | Active | April 16, 2026 |
| [GH-900](https://learn.microsoft.com/credentials/certifications/resources/study-guides/gh-900) | GitHub Foundations (optional) | Active | Not shown |

None of these exams is on the retirement page, and none is renamed. Where this page differs from the plan it was built from:

- **AZ-400 prerequisite.** The DevOps Engineer Expert certification needs the Azure Administrator Associate or the Azure Developer Associate certification. AI-200 isn't listed, so a developer who holds only GH-300 and AI-200 can sit AZ-400 but should add AZ-104 to earn the certification.
- **DP-800 on Infra and Database Migration.** The partner page lists it as a separate group with no "OR". The owner decided on October 10, 2026 to treat it as a required group, so the role tracks and the sample plan include it.
- **Partner Center lag.** The Infrastructure designation still lists the Windows Server Hybrid Administrator certification, although AZ-800 and AZ-801 retired. The Digital & App Innovation designation page doesn't yet list AI-200 or GH-600, which the June 2026 partner announcement adds. Check Partner Center before you rely on either list.
- **No outline date yet.** The SC-500, AI-200, GH-600 and GH-900 study guides show no skills outline date. The AI-200 and SC-500 practice assessments aren't available yet.
