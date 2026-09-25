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
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            SchoolContext db,
            NotificationService notificationService,
            ILogger<NotificationsController> logger)
            : base(db, notificationService)
        {
            _logger = logger;
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
                _logger.LogError(ex, "Error retrieving notifications");
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
                System.Diagnostics.Debug.WriteLine($"Error marking notification as read: {ex.Message}");
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
