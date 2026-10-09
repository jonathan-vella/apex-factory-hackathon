---
name: aspnet-startup-migration
description: Check that Contoso University's Global.asax, RouteConfig, FilterConfig and BundleConfig moved to Program.cs and static files in wwwroot, and guide the fix if anything is left. Use when System.Web, Global.asax or App_Start code is left after the .NET 10 upgrade, or when CSS or JavaScript doesn't load.
---

# ASP.NET startup migration

## When to use

After task 01 (.NET 10 and ASP.NET Core MVC), if any of these is true:

- `Global.asax`, `Global.asax.cs` or `App_Start/` still exists in `app/ContosoUniversity`.
- `git grep -n -E "System\.Web|Styles\.Render|Scripts\.Render" -- app/ContosoUniversity` prints anything.
- A page loads without its styles or scripts, or a request for a `.css` or `.js` file returns 404.

Scope: `app/ContosoUniversity` only.

## Steps

1. **Routes.** `RouteConfig` maps `{controller}/{action}/{id}` with `Home` and `Index` as defaults. `Program.cs` needs the same route: `app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}")` after `app.UseRouting()`. Then `RouteConfig.cs` goes.
2. **Filters.** `FilterConfig` registers `HandleErrorAttribute`. Its replacement is `app.UseExceptionHandler("/Home/Error")` outside Development and `app.UseDeveloperExceptionPage()` in Development. `Views/Shared/Error.cshtml` must work without `HttpContext.Current`. Then `FilterConfig.cs` goes.
3. **Bundles.** ASP.NET Core has no `System.Web.Optimization`. Each file in `BundleConfig` moves into `wwwroot` (`Content/` to `wwwroot/css/`, `Scripts/` to `wwwroot/js/` or `wwwroot/lib/`). The views use `<link>` and `<script>` tags instead of `@Styles.Render` and `@Scripts.Render`, and `Program.cs` calls `app.UseStaticFiles()`. Then `BundleConfig.cs` goes.
4. **Case.** App Service for Linux has a case-sensitive file system, so every file name must match every reference exactly. The legacy bundle asks for `site.css`, but the file is `Site.css`.
5. **Startup work.** Anything else in `Application_Start`, such as the database initializer, moves to `Program.cs` after `builder.Build()`.
6. `Global.asax`, `Global.asax.cs`, `App_Start/` and the `System.Web` usings go.

Ask Copilot for the missing steps only, then run the checks.

## Checks

- `dotnet build app/ContosoUniversity` passes.
- `git grep -n -E "System\.Web|Optimization|Global\.asax" -- app/ContosoUniversity` prints nothing.
- `dotnet run`: the home, Students, Courses, Instructors and Departments pages load with their styles, and no request for a `.css` or `.js` file returns 404 in the browser's developer tools.

## Example

Before, in `Global.asax.cs` and `App_Start/BundleConfig.cs`:

```csharp
protected void Application_Start()
{
    AreaRegistration.RegisterAllAreas();
    FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
    RouteConfig.RegisterRoutes(RouteTable.Routes);
    BundleConfig.RegisterBundles(BundleTable.Bundles);
}

bundles.Add(new StyleBundle("~/Content/css").Include("~/Content/bootstrap.css", "~/Content/site.css"));
```

After, in `Program.cs` and `Views/Shared/_Layout.cshtml`:

```csharp
builder.Services.AddControllersWithViews();
var app = builder.Build();

if (app.Environment.IsDevelopment()) app.UseDeveloperExceptionPage();
else app.UseExceptionHandler("/Home/Error");

app.UseStaticFiles();
app.UseRouting();
app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");
app.Run();
```

```html
<link href="~/css/site.css" rel="stylesheet" />
```
