using ContosoUniversity.Data;
using ContosoUniversity.Services;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System.Net;

var builder = WebApplication.CreateBuilder(args);

if (!builder.Environment.IsDevelopment())
{
	var vaultUriSetting = builder.Configuration["KeyVault:VaultUri"];
	if (!Uri.TryCreate(vaultUriSetting, UriKind.Absolute, out var vaultUri) ||
		!string.Equals(vaultUri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase) ||
		!vaultUri.IsDefaultPort ||
		!string.Equals(vaultUri.AbsolutePath, "/", StringComparison.Ordinal) ||
		!string.IsNullOrEmpty(vaultUri.UserInfo) ||
		!string.IsNullOrEmpty(vaultUri.Query) ||
		!string.IsNullOrEmpty(vaultUri.Fragment) ||
		IPAddress.TryParse(vaultUri.Host, out _) ||
		vaultUri.Host.Contains("privatelink", StringComparison.OrdinalIgnoreCase) ||
		!vaultUri.Host.EndsWith(".vault.azure.net", StringComparison.OrdinalIgnoreCase))
	{
		throw new InvalidOperationException(
			"KeyVault:VaultUri is required outside Development and must be an HTTPS standard *.vault.azure.net hostname resolved through private DNS.");
	}

	try
	{
		builder.Configuration.AddAzureKeyVault(vaultUri, new DefaultAzureCredential());
	}
	catch (Exception exception)
	{
		throw new InvalidOperationException(
			"Failed to load mandatory Key Vault configuration. Verify the private vault endpoint and DefaultAzureCredential access.",
			exception);
	}

	var keyVaultProvider = ((IConfigurationRoot)builder.Configuration).Providers.Last();
	if (!keyVaultProvider.TryGet("ConnectionStrings:DefaultConnection", out var keyVaultConnectionString) ||
		string.IsNullOrWhiteSpace(keyVaultConnectionString))
	{
		throw new InvalidOperationException(
			"Key Vault must contain a non-empty ConnectionStrings--DefaultConnection secret.");
	}
}

var applicationInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
{
	applicationInsightsConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
}

if (!string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
{
	builder.Services.AddOpenTelemetry().UseAzureMonitor(options =>
	{
		options.ConnectionString = applicationInsightsConnectionString;
		options.Credential = new DefaultAzureCredential();
	});
}

builder.Host.UseDefaultServiceProvider(options =>
{
	options.ValidateOnBuild = true;
	options.ValidateScopes = true;
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
	throw new InvalidOperationException(
		"ConnectionStrings:DefaultConnection is required. Configure it with .NET user secrets in Development or the approved managed configuration source outside Development.");
}

SqlConnectionStringBuilder sqlConnectionString;
try
{
	sqlConnectionString = new SqlConnectionStringBuilder(connectionString);
}
catch (ArgumentException)
{
	throw new InvalidOperationException("ConnectionStrings:DefaultConnection is not a valid SQL Server connection string.");
}

if (!builder.Environment.IsDevelopment())
{
	if (!string.IsNullOrWhiteSpace(sqlConnectionString.UserID) ||
		!string.IsNullOrWhiteSpace(sqlConnectionString.Password))
	{
		throw new InvalidOperationException("SQL usernames and passwords are not allowed outside Development.");
	}

	if (sqlConnectionString.IntegratedSecurity)
	{
		throw new InvalidOperationException("Integrated security is not allowed outside Development; use Authentication=Active Directory Default.");
	}

	if (sqlConnectionString.Authentication != SqlAuthenticationMethod.ActiveDirectoryDefault)
	{
		throw new InvalidOperationException("Outside Development, ConnectionStrings:DefaultConnection must use Authentication=Active Directory Default.");
	}

	var dataSource = sqlConnectionString.DataSource.Trim();
	if (dataSource.StartsWith("tcp:", StringComparison.OrdinalIgnoreCase))
	{
		dataSource = dataSource[4..];
	}

	var portSeparator = dataSource.LastIndexOf(',');
	var host = (portSeparator < 0 ? dataSource : dataSource[..portSeparator]).Trim().TrimEnd('.');
	var port = portSeparator < 0 ? string.Empty : dataSource[(portSeparator + 1)..].Trim();
	var hasPublicDnsLabel = host.Split('.', StringSplitOptions.RemoveEmptyEntries)
		.Any(label => string.Equals(label, "public", StringComparison.OrdinalIgnoreCase));
	if ((port.Length > 0 && !string.Equals(port, "1433", StringComparison.OrdinalIgnoreCase)) ||
		hasPublicDnsLabel ||
		host.Contains("privatelink", StringComparison.OrdinalIgnoreCase) ||
		IPAddress.TryParse(host.Trim('[', ']'), out _) ||
		!host.EndsWith(".database.windows.net", StringComparison.OrdinalIgnoreCase))
	{
		throw new InvalidOperationException("Outside Development, the SQL endpoint must use the standard private-DNS Managed Instance hostname and not an IP, public or privatelink hostname, or nonstandard port.");
	}
}

builder.Services.AddDbContext<SchoolContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddSingleton<INotificationService, NotificationService>();
builder.Services.AddSingleton<ITeachingMaterialStorage, AzureBlobTeachingMaterialStorage>();
builder.Services.AddControllersWithViews();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
	app.UseExceptionHandler("/Home/Error");
}

using (var scope = app.Services.CreateScope())
{
	_ = scope.ServiceProvider.GetRequiredService<SchoolContext>();
	_ = scope.ServiceProvider.GetRequiredService<INotificationService>();
	_ = scope.ServiceProvider.GetRequiredService<ITeachingMaterialStorage>();
}

app.UseStaticFiles();

app.MapGet("/health", () => "ok");
app.MapControllerRoute(
	name: "default",
	pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();