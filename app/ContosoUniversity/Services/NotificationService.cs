using ContosoUniversity.Models;

namespace ContosoUniversity.Services
{
    public sealed class NotificationService : INotificationService
    {
        private const string UnavailableMessage =
            "Notification messaging is unavailable until task 04 replaces the legacy MSMQ implementation.";

        public void SendNotification(
            string entityType,
            string entityId,
            EntityOperation operation,
            string userName = null)
        {
            throw CreateUnavailableException();
        }

        public void SendNotification(
            string entityType,
            string entityId,
            string entityDisplayName,
            EntityOperation operation,
            string userName = null)
        {
            throw CreateUnavailableException();
        }

        public Notification ReceiveNotification()
        {
            throw CreateUnavailableException();
        }

        public void MarkAsRead(int notificationId)
        {
            throw CreateUnavailableException();
        }

        private static NotSupportedException CreateUnavailableException()
        {
            return new NotSupportedException(UnavailableMessage);
        }
    }
}
