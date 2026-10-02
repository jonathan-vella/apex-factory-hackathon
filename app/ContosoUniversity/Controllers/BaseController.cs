using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ContosoUniversity.Services;
using ContosoUniversity.Models;
using ContosoUniversity.Data;

namespace ContosoUniversity.Controllers
{
    public abstract class BaseController : Controller
    {
        protected readonly SchoolContext db;
        protected readonly NotificationService notificationService;

        protected BaseController(SchoolContext db, NotificationService notificationService)
        {
            this.db = db;
            this.notificationService = notificationService;
        }

        protected void SendEntityNotification(string entityType, string entityId, EntityOperation operation)
        {
            SendEntityNotification(entityType, entityId, null, operation);
        }

        protected void SendEntityNotification(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            try
            {
                var userName = "System"; // No authentication, use System as default user
                notificationService.SendNotification(entityType, entityId, entityDisplayName, operation, userName);
            }
            catch (Exception ex)
            {
                // Log the error but don't break the main operation
                HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger(GetType())
                    .LogError(ex, "Failed to send {EntityType} notification for {EntityId}", entityType, entityId);
            }
        }
    }
}
