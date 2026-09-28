using ContosoUniversity.Data;
using ContosoUniversity.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseDefaultServiceProvider(options =>
{
	options.ValidateOnBuild = true;
	options.ValidateScopes = true;
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<SchoolContext>(options =>
{
	if (!string.IsNullOrWhiteSpace(connectionString))
	{
		options.UseSqlServer(connectionString);
	}
});
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddControllersWithViews();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
	app.UseExceptionHandler("/Home/Error");
}

var uploadsRoot = Path.Combine(app.Environment.ContentRootPath, "Uploads");
Directory.CreateDirectory(Path.Combine(uploadsRoot, "TeachingMaterials"));

using (var scope = app.Services.CreateScope())
{
	_ = scope.ServiceProvider.GetRequiredService<SchoolContext>();
	_ = scope.ServiceProvider.GetRequiredService<INotificationService>();
}

app.UseStaticFiles();
app.UseStaticFiles(new StaticFileOptions
{
	FileProvider = new PhysicalFileProvider(uploadsRoot),
	RequestPath = "/Uploads"
});

app.MapGet("/health", () => "ok");
app.MapControllerRoute(
	name: "default",
	pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();