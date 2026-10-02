using System;
using System.IO;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Azure.Security.KeyVault.Secrets;
using ContosoUniversity.Data;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;

const long MaxRequestBodyBytes = 10 * 1024 * 1024;

var builder = WebApplication.CreateBuilder(args);

// Key Vault is added last so it overrides env/appsettings; in Development an existing DefaultConnection (user secret) is never replaced.
var vaultUri = builder.Configuration["KeyVault:VaultUri"];
if (!string.IsNullOrWhiteSpace(vaultUri))
{
    if (!Uri.TryCreate(vaultUri, UriKind.Absolute, out var vaultUriParsed))
    {
        throw new InvalidOperationException("KeyVault:VaultUri is not a valid absolute URI.");
    }

    var keepLocalConnection = builder.Environment.IsDevelopment()
        && !string.IsNullOrWhiteSpace(builder.Configuration.GetConnectionString("DefaultConnection"));
    builder.Configuration.AddAzureKeyVault(
        vaultUriParsed,
        new DefaultAzureCredential(),
        new LocalFirstSecretManager(keepLocalConnection));
}
else if (!builder.Environment.IsDevelopment())
{
    throw new InvalidOperationException(
        "KeyVault:VaultUri is not configured. Outside Development set it (for example via the KeyVault__VaultUri app setting).");
}

// Telemetry is opt-in: with no connection string the built-in console logging applies. Ingestion uses Entra auth (local auth is disabled).
if (!string.IsNullOrWhiteSpace(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"])
    || !string.IsNullOrWhiteSpace(builder.Configuration["ApplicationInsights:ConnectionString"]))
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor(o =>
    {
        var configured = builder.Configuration["ApplicationInsights:ConnectionString"];
        if (!string.IsNullOrWhiteSpace(configured))
        {
            o.ConnectionString = configured;
        }
        o.Credential = new DefaultAzureCredential();
    });
}

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection is not configured. In Development set it with 'dotnet user-secrets set \"ConnectionStrings:DefaultConnection\" \"<value>\"'.");
}

// Outside Development the connection must use Entra auth (Authentication=Active Directory Default); never echo the value.
if (!builder.Environment.IsDevelopment())
{
    var csb = new SqlConnectionStringBuilder(connectionString);
    if (!string.IsNullOrEmpty(csb.UserID) || !string.IsNullOrEmpty(csb.Password))
    {
        throw new InvalidOperationException(
            "ConnectionStrings:DefaultConnection must not contain a user name or password outside Development. Use 'Authentication=Active Directory Default'.");
    }
}

builder.Services.Configure<KestrelServerOptions>(o => o.Limits.MaxRequestBodySize = MaxRequestBodyBytes);
builder.Services.Configure<FormOptions>(o => o.MultipartBodyLengthLimit = MaxRequestBodyBytes);

builder.Services.AddDbContext<SchoolContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddSingleton<NotificationService>();
builder.Services.AddSingleton<TeachingMaterialStore>();

// MVC 5 serialized JSON with property names as declared; keep that for the notifications poll.
builder.Services.AddControllersWithViews()
    .AddJsonOptions(o => o.JsonSerializerOptions.PropertyNamingPolicy = null);

var app = builder.Build();

// Fail fast when Storage or Service Bus settings are missing.
_ = app.Services.GetRequiredService<TeachingMaterialStore>();
_ = app.Services.GetRequiredService<NotificationService>();

using (var scope = app.Services.CreateScope())
{
    DbInitializer.Initialize(scope.ServiceProvider.GetRequiredService<SchoolContext>());
}

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
}

app.UseStaticFiles();

app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
