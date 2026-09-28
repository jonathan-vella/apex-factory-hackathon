using System;
using System.Collections.Generic;
using System.Text.Json;
using ContosoUniversity.Data;
using ContosoUniversity.Models;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Mvc;

namespace ContosoUniversity.Controllers
{
    public class NotificationsController : BaseController
    {
        private static readonly JsonSerializerOptions ContractJsonOptions = new()
        {
            PropertyNamingPolicy = null
        };

        public NotificationsController(
            SchoolContext db,
            INotificationService notificationService)
            : base(db, notificationService)
        {
        }

        [HttpGet]
        public JsonResult GetNotifications()
        {
            var notifications = new List<Notification>();

            try
            {
                Notification notification;
                while ((notification = notificationService.ReceiveNotification()) != null)
                {
                    notifications.Add(notification);

                    if (notifications.Count >= 10)
                    {
                        break;
                    }
                }
            }
            catch (Exception)
            {
                return ContractJson(new
                {
                    success = false,
                    message = "Error retrieving notifications"
                });
            }

            return ContractJson(new
            {
                success = true,
                notifications = notifications,
                count = notifications.Count
            });
        }

        [HttpPost]
        public JsonResult MarkAsRead(int id)
        {
            try
            {
                notificationService.MarkAsRead(id);
                return ContractJson(new { success = true });
            }
            catch (Exception)
            {
                return ContractJson(new
                {
                    success = false,
                    message = "Error updating notification"
                });
            }
        }

        public IActionResult Index()
        {
            return View();
        }

        private static JsonResult ContractJson(object value)
        {
            return new JsonResult(value, ContractJsonOptions);
        }
    }
}
