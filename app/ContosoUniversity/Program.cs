using ContosoUniversity.Data;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Http.Timeouts;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection must be configured.");
var requestBodyLimit = builder.Configuration.GetValue<long>("Kestrel:Limits:MaxRequestBodySize");
var requestTimeout = TimeSpan.FromSeconds(builder.Configuration.GetValue<int>("RequestTimeoutSeconds"));

builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = requestBodyLimit);
builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = requestBodyLimit);
builder.Services.AddRequestTimeouts(options =>
{
    options.DefaultPolicy = new RequestTimeoutPolicy { Timeout = requestTimeout };
});
builder.Services.AddDbContext<SchoolContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddSingleton<NotificationService>();
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
