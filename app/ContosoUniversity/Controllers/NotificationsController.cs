using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ContosoUniversity.Data;
using ContosoUniversity.Services;
using ContosoUniversity.Models;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Controllers
{
    public class NotificationsController : BaseController
    {
        public NotificationsController(
            SchoolContext db,
            NotificationService notificationService,
            ILogger<NotificationsController> logger)
            : base(db, notificationService, logger)
        {
        }

        // GET: api/notifications - Get pending notifications for admin
        [HttpGet]
        public async Task<JsonResult> GetNotifications()
        {
            var notifications = new List<Notification>();
            
            try
            {
                notifications.AddRange(
                    await notificationService.ReceiveNotificationsAsync(10, HttpContext.RequestAborted));
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error retrieving notifications");
                return Json(new { success = false, message = "Error retrieving notifications" });
            }

            return Json(new { 
                success = true, 
                notifications = notifications,
                count = notifications.Count 
            });
        }

        // POST: api/notifications/mark-read
        [HttpPost]
        public JsonResult MarkAsRead(int id)
        {
            try
            {
                notificationService.MarkAsRead(id);
                return Json(new { success = true });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error marking notification {NotificationId} as read", id);
                return Json(new { success = false, message = "Error updating notification" });
            }
        }

        // GET: Notifications/Index - Admin notification dashboard
        public ActionResult Index()
        {
            return View();
        }
    }
}
