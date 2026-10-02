using System;
using System.IO;
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

// MVC 5 serialized JSON with property names as declared; keep that for the notifications poll.
builder.Services.AddControllersWithViews()
    .AddJsonOptions(o => o.JsonSerializerOptions.PropertyNamingPolicy = null);

var app = builder.Build();

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

// Teaching-material uploads stay on local disk until the Blob Storage task.
var uploadsRoot = Path.Combine(app.Environment.ContentRootPath, "Uploads");
Directory.CreateDirectory(Path.Combine(uploadsRoot, "TeachingMaterials"));
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsRoot),
    RequestPath = "/Uploads"
});

app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
