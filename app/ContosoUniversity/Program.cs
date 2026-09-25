using Azure.Monitor.OpenTelemetry.AspNetCore;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using ContosoUniversity.Data;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Http.Timeouts;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);
var applicationInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
{
    applicationInsightsConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
}

var keyVaultUri = builder.Configuration["KeyVault:VaultUri"];
if (!string.IsNullOrWhiteSpace(keyVaultUri))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUri, UriKind.Absolute),
        new DefaultAzureCredential());
}

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection must be configured.");
var serviceBusNamespace = builder.Configuration["ServiceBus:FullyQualifiedNamespace"];
if (string.IsNullOrWhiteSpace(serviceBusNamespace))
{
    throw new InvalidOperationException("ServiceBus:FullyQualifiedNamespace must be configured.");
}

var serviceBusQueueName = builder.Configuration["ServiceBus:QueueName"];
if (string.IsNullOrWhiteSpace(serviceBusQueueName))
{
    throw new InvalidOperationException("ServiceBus:QueueName must be configured.");
}

var requestBodyLimit = builder.Configuration.GetValue<long>("Kestrel:Limits:MaxRequestBodySize");
var requestTimeout = TimeSpan.FromSeconds(builder.Configuration.GetValue<int>("RequestTimeoutSeconds"));

builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = requestBodyLimit);
builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = requestBodyLimit);
builder.Services.AddRequestTimeouts(options =>
{
    options.DefaultPolicy = new RequestTimeoutPolicy { Timeout = requestTimeout };
});
builder.Services.AddDbContext<SchoolContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddSingleton<ITeachingMaterialImageStorage, BlobTeachingMaterialImageStorage>();
builder.Services.AddSingleton<ServiceBusClient>(_ =>
    new ServiceBusClient(serviceBusNamespace, new DefaultAzureCredential()));
builder.Services.AddSingleton<NotificationService>(serviceProvider =>
    new NotificationService(
        serviceProvider.GetRequiredService<ServiceBusClient>(),
        serviceBusQueueName,
        serviceProvider.GetRequiredService<ILogger<NotificationService>>()));
var openTelemetry = builder.Services.AddOpenTelemetry();
if (!string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
{
    openTelemetry.UseAzureMonitor(options =>
        options.ConnectionString = applicationInsightsConnectionString);
}
else
{
    openTelemetry
        .WithTracing(tracing => tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation()
            .AddSqlClientInstrumentation()
            .AddConsoleExporter())
        .WithMetrics(metrics => metrics
            .AddMeter(
                "Microsoft.AspNetCore.Hosting",
                "Microsoft.AspNetCore.Server.Kestrel",
                "System.Net.Http",
                "System.Runtime")
            .AddConsoleExporter());
}

builder.Logging.AddOpenTelemetry(options =>
{
    options.IncludeFormattedMessage = true;
    options.IncludeScopes = true;
    options.ParseStateValues = true;
    if (string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
    {
        options.AddConsoleExporter();
    }
});
builder.Services.AddControllersWithViews()
    .AddJsonOptions(options => options.JsonSerializerOptions.PropertyNamingPolicy = null);

var app = builder.Build();

if (builder.Configuration.GetValue("Database:InitializeOnStartup", true))
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<SchoolContext>();
    DbInitializer.Initialize(context);
}

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseRequestTimeouts();
app.UseAuthorization();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
