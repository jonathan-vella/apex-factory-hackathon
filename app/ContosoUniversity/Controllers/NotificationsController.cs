using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ContosoUniversity.Data;
using ContosoUniversity.Models;
using ContosoUniversity.Services;

namespace ContosoUniversity.Controllers
{
    public class NotificationsController : BaseController
    {
        private readonly ILogger<NotificationsController> logger;

        public NotificationsController(SchoolContext db, NotificationService notificationService, ILogger<NotificationsController> logger) : base(db, notificationService)
        {
            this.logger = logger;
        }

        // GET: Notifications/GetNotifications - Get pending notifications for admin
        [HttpGet]
        public IActionResult GetNotifications()
        {
            IList<Notification> notifications;

            try
            {
                // Up to 10 per poll to avoid overwhelming the UI
                notifications = notificationService.ReceiveNotifications();
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

        // POST: Notifications/MarkAsRead
        [HttpPost]
        public IActionResult MarkAsRead(int id)
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
        public IActionResult Index()
        {
            return View();
        }
    }
}
