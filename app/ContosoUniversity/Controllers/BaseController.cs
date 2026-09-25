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
        protected readonly NotificationService notificationService;
        protected readonly ILogger logger;

        protected BaseController(
            SchoolContext db,
            NotificationService notificationService,
            ILogger logger)
        {
            this.db = db;
            this.notificationService = notificationService;
            this.logger = logger;
        }

        protected Task SendEntityNotificationAsync(string entityType, string entityId, EntityOperation operation)
        {
            return SendEntityNotificationAsync(entityType, entityId, null, operation);
        }

        protected async Task SendEntityNotificationAsync(
            string entityType,
            string entityId,
            string entityDisplayName,
            EntityOperation operation)
        {
            try
            {
                var userName = "System"; // No authentication, use System as default user
                await notificationService.SendNotificationAsync(
                    entityType,
                    entityId,
                    entityDisplayName,
                    operation,
                    userName);
            }
            catch (Exception ex)
            {
                // Log the error but don't break the main operation
                logger.LogError(
                    ex,
                    "Failed to send {Operation} notification for {EntityType} {EntityId}",
                    operation,
                    entityType,
                    entityId);
            }
        }

    }
}
