# 01.04-static-shared-razor: Migrate shared Razor infrastructure, bundling, and static assets

# 01.04 Shared Razor infrastructure and static assets

## Objective
Create the ASP.NET Core Razor/static-file foundation that each feature controller subtask can use, independently from controller logic.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Views/_ViewStart.cshtml`, new `Views/_ViewImports.cshtml`, `Views/Shared/_Layout.cshtml`, `Views/Shared/Error.cshtml`
- `Content/`, `Scripts/`, favicon, and target `wwwroot/`
- `App_Start/BundleConfig.cs` and static-file middleware in `Program.cs`

## Steps
1. Move immutable CSS/JavaScript/favicon assets to a case-consistent `wwwroot` layout and enable static-file middleware. Do not move mutable teaching materials to Blob; task 03 owns that migration.
2. Remove `System.Web.Optimization` rendering and use direct local asset references with equivalent load order and client validation behavior.
3. Add Core Tag Helper imports and migrate the shared layout/error view away from System.Web types while preserving navigation and visible behavior.
4. Reconcile assessed discrepancies for `notifications.css`, `notifications.js`, and `Site.css` casing/inclusion. Preserve the notification script's endpoint and JSON expectations.
5. Build and verify all referenced static files resolve from the running host.

## Done when
Shared Razor infrastructure compiles, static assets load with no missing/case-mismatched references, no bundle render calls remain in shared views, and no Blob/telemetry implementation was added.

## Execution research

### Confirmed scope and current state
- The single affected project is `app/ContosoUniversity/ContosoUniversity.csproj`, already converted by prior children to `Microsoft.NET.Sdk.Web` and `net10.0`; it has no project dependencies or test project.
- `Program.cs` currently exposes only `/health`. It has no MVC service registration, static-file middleware, or controller route. This child must add the shared Razor/static-file foundation without including controller or feature-view slices owned by later children.
- The SDK project currently removes all `Views/**/*.cshtml` from `Content` and `RazorGenerate`. Re-include only `Views/_ViewStart.cshtml`, new `Views/_ViewImports.cshtml`, `Views/Shared/_Layout.cshtml`, and `Views/Shared/Error.cshtml` here.
- No `// STUB:` markers exist in the affected project.

### Assessment findings to address
- The generated project assessment reports nine mandatory `Feature.0001` occurrences: `System.Web.Optimization` bundling is unsupported and must become direct HTML asset references.
- `Microsoft.AspNet.Web.Optimization` 1.1.3 has no supported target version. It is already absent from the converted SDK project; this child removes its remaining source/view usage and deletes `App_Start/BundleConfig.cs`.
- ASP.NET MVC/Razor/WebPages package functionality is supplied by the ASP.NET Core framework reference. Add `_ViewImports.cshtml` with the application/model namespaces and `Microsoft.AspNetCore.Mvc.TagHelpers` rather than restoring legacy packages.
- The existing wire-compatibility record in `breakdown-context.md` is PASS for the MVC host. This child preserves the coordinated notification consumer: `/Notifications/GetNotifications`, the `{ success, notifications, count }` envelope, and PascalCase notification members remain unchanged in `notifications.js`. No endpoint, serializer, or controller is changed here. See the scoped [wire-compatibility record](progress-details.md#wire-compatibility).

### Static asset inventory and reconciliation
- Existing immutable assets are `Content/Site.css`, `Content/notifications.css`, and 18 files under `Scripts/`. Move runtime assets to case-consistent `wwwroot/css` and `wwwroot/js`; exclude development-only `*-vsdoc.js`, source maps, slim jQuery duplicates, and unminified duplicates not referenced by the direct production tags.
- Preserve bundle load order in direct tags: site styles, notification styles, Modernizr in `<head>`, then jQuery, Bootstrap, Respond, notification polling, and per-view validation scripts at the end of `<body>`.
- The legacy bundle names `Content/bootstrap.css`, but neither the working tree nor repository history contains Bootstrap CSS. The project file's Bootstrap CSS and `favicon.ico` entries are stale; no favicon exists in the working tree or history. Restore a local Bootstrap 3.4.1 stylesheet matching the existing Bootstrap 3.4.1 JavaScript and remove the nonexistent favicon entry instead of creating a fabricated icon.
- Normalize `Site.css` to lowercase `site.css` and use lowercase URL paths consistently. Keep notification endpoint and JSON-property usage byte-for-byte equivalent apart from its file relocation.
- `Uploads/TeachingMaterials` remains outside `wwwroot`; mutable teaching materials and Blob storage are explicitly outside this child.

### Validation plan
- Build `ContosoUniversity.csproj` with zero errors and warnings so Razor compilation checks the four included shared views.
- Start the host on a fixed local HTTP URL and verify `/health` plus every layout asset URL returns HTTP 200 with the expected content type.
- Search for remaining `System.Web.Optimization`, `BundleConfig`, `Scripts.Render`, `Styles.Render`, and case-inconsistent `/Content` or `/Scripts` references in this child's shared scope.

### Decomposition verdict
Atomic. Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`. This child is already the isolated `web-bundling-and-static-assets` unit; controller, authentication, DI, messaging, data, Blob, telemetry, and feature-view work is owned by other tasks. No matching hint requires another split.
