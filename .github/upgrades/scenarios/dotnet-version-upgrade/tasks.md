# Migration Progress

**Progress**: 17/19 tasks complete <progress value="89" max="100"></progress> 89%
**Status**: Not Started

## Tasks

- ✅ 01-upgrade-dotnet-aspnet-core: Upgrade to .NET 10 and ASP.NET Core MVC ([Content](tasks/01-upgrade-dotnet-aspnet-core/task.md), [Progress](tasks/01-upgrade-dotnet-aspnet-core/progress-details.md))
  - ✅ 01.01-wire-contract-baseline: Record the MVC endpoint baseline and mandatory wire-contract gate ([Content](tasks/01.01-wire-contract-baseline/task.md), [Progress](tasks/01.01-wire-contract-baseline/progress-details.md))
  - ✅ 01.02-sdk-host: Convert the project to SDK-style net10.0 and establish a minimal Core host ([Content](tasks/01.02-sdk-host/task.md), [Progress](tasks/01.02-sdk-host/progress-details.md))
  - ✅ 01.03-configuration-di-boundaries: Migrate configuration and create compile-safe DI boundaries for deferred services ([Content](tasks/01.03-configuration-di-boundaries/task.md), [Progress](tasks/01.03-configuration-di-boundaries/progress-details.md))
  - ✅ 01.04-static-shared-razor: Migrate shared Razor infrastructure, bundling, and static assets ([Content](tasks/01.04-static-shared-razor/task.md), [Progress](tasks/01.04-static-shared-razor/progress-details.md))
  - ✅ 01.05-base-controller: Migrate BaseController to ASP.NET Core MVC and constructor injection ([Content](tasks/01.05-base-controller/task.md), [Progress](tasks/01.05-base-controller/progress-details.md))
  - ✅ 01.06-home-controller: Migrate HomeController and its Razor views ([Content](tasks/01.06-home-controller/task.md), [Progress](tasks/01.06-home-controller/progress-details.md))
  - ✅ 01.07-students-controller: Migrate StudentsController and student Razor views ([Content](tasks/01.07-students-controller/task.md), [Progress](tasks/01.07-students-controller/progress-details.md))
  - ✅ 01.08-departments-controller: Migrate DepartmentsController and department Razor views ([Content](tasks/01.08-departments-controller/task.md), [Progress](tasks/01.08-departments-controller/progress-details.md))
  - ✅ 01.09-instructors-controller: Migrate InstructorsController and instructor Razor views ([Content](tasks/01.09-instructors-controller/task.md), [Progress](tasks/01.09-instructors-controller/progress-details.md))
  - ✅ 01.10-courses-controller: Migrate CoursesController while preserving the later Blob boundary ([Content](tasks/01.10-courses-controller/task.md), [Progress](tasks/01.10-courses-controller/progress-details.md))
  - ✅ 01.11-notifications-controller: Migrate NotificationsController and preserve its raw JSON contract ([Content](tasks/01.11-notifications-controller/task.md), [Progress](tasks/01.11-notifications-controller/progress-details.md))
  - ✅ 01.12-cleanup-container-validation: Remove legacy host remnants and validate build, pages, and SDK container publishing ([Content](tasks/01.12-cleanup-container-validation/task.md), [Progress](tasks/01.12-cleanup-container-validation/progress-details.md))
- ✅ 02-azure-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance ([Content](tasks/02-azure-sql-managed-instance/task.md), [Progress](tasks/02-azure-sql-managed-instance/progress-details.md))
- ✅ 03-azure-blob-storage: Migrate mutable file handling to Azure Blob Storage ([Content](tasks/03-azure-blob-storage/task.md), [Progress](tasks/03-azure-blob-storage/progress-details.md))
- ✅ 04-azure-service-bus: Migrate messaging to Azure Service Bus ([Content](tasks/04-azure-service-bus/task.md), [Progress](tasks/04-azure-service-bus/progress-details.md))
- ✅ 05-azure-key-vault: Integrate Azure Key Vault ([Content](tasks/05-azure-key-vault/task.md), [Progress](tasks/05-azure-key-vault/progress-details.md))
- 🔲 06-opentelemetry-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor ([Content](tasks/06-opentelemetry-azure-monitor/task.md))
- 🔲 07-dependency-cve-audit: Audit and remediate dependency CVEs ([Content](tasks/07-dependency-cve-audit/task.md))

**Legend**: ✅ Complete | 🔄 In Progress | 🔲 Pending | ⚠️ Blocked | ❌ Failed
