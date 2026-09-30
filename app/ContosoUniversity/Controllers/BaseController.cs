using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ContosoUniversity.Services;
using ContosoUniversity.Models;
using ContosoUniversity.Data;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Controllers
{
    public abstract class BaseController : Controller
    {
        protected readonly SchoolContext db;
        protected readonly INotificationService notificationService;
        protected readonly ILogger<BaseController> baseLogger;

        protected BaseController(
            SchoolContext db,
            INotificationService notificationService,
            ILogger<BaseController> baseLogger)
        {
            this.db = db;
            this.notificationService = notificationService;
            this.baseLogger = baseLogger;
        }

        protected Task SendEntityNotificationAsync(string entityType, string entityId, EntityOperation operation)
        {
            return SendEntityNotificationAsync(entityType, entityId, null, operation);
        }

        protected async Task SendEntityNotificationAsync(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            try
            {
                var userName = "System"; // No authentication, use System as default user
                await notificationService.SendNotificationAsync(entityType, entityId, entityDisplayName, operation, userName);
            }
            catch (Exception ex)
            {
                baseLogger.LogError(ex, "Failed to send notification for {EntityType} {EntityId}.", entityType, entityId);
            }
        }

    }
}
