using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using ContosoUniversity.Models;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Services
{
    public class NotificationService : IAsyncDisposable
    {
        private readonly ServiceBusSender _sender;
        private readonly ServiceBusReceiver _receiver;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(
            ServiceBusClient serviceBusClient,
            string queueName,
            ILogger<NotificationService> logger)
        {
            if (string.IsNullOrWhiteSpace(queueName))
            {
                throw new ArgumentException("A Service Bus queue name is required.", nameof(queueName));
            }

            _sender = serviceBusClient.CreateSender(queueName);
            _receiver = serviceBusClient.CreateReceiver(
                queueName,
                new ServiceBusReceiverOptions { ReceiveMode = ServiceBusReceiveMode.ReceiveAndDelete });
            _logger = logger;
        }

        public Task SendNotificationAsync(
            string entityType,
            string entityId,
            EntityOperation operation,
            string userName = null)
        {
            return SendNotificationAsync(entityType, entityId, null, operation, userName);
        }

        public async Task SendNotificationAsync(
            string entityType,
            string entityId,
            string entityDisplayName,
            EntityOperation operation,
            string userName = null)
        {
            try
            {
                var notification = new Notification
                {
                    EntityType = entityType,
                    EntityId = entityId,
                    Operation = operation.ToString(),
                    Message = GenerateMessage(entityType, entityId, entityDisplayName, operation),
                    CreatedAt = DateTime.Now,
                    CreatedBy = userName ?? "System",
                    IsRead = false
                };
                var message = new ServiceBusMessage(JsonSerializer.Serialize(notification))
                {
                    ContentType = "application/json"
                };

                await _sender.SendMessageAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to send notification for {EntityType} {EntityId}",
                    entityType,
                    entityId);
            }
        }

        public async Task<IReadOnlyList<Notification>> ReceiveNotificationsAsync(
            int maxMessages,
            CancellationToken cancellationToken = default)
        {
            var messages = await _receiver.ReceiveMessagesAsync(
                maxMessages,
                TimeSpan.FromSeconds(2),
                cancellationToken);
            var notifications = new List<Notification>(messages.Count);

            foreach (var message in messages)
            {
                var notification = JsonSerializer.Deserialize<Notification>(message.Body.ToString());
                if (notification == null)
                {
                    throw new JsonException("A Service Bus message did not contain a notification.");
                }

                notifications.Add(notification);
            }

            return notifications;
        }

        public void MarkAsRead(int notificationId)
        {
            // The existing notification flow does not persist read status.
        }

        public async ValueTask DisposeAsync()
        {
            await _sender.DisposeAsync();
            await _receiver.DisposeAsync();
        }

        private string GenerateMessage(string entityType, string entityId, string entityDisplayName, EntityOperation operation)
        {
            var displayText = !string.IsNullOrWhiteSpace(entityDisplayName)
                ? $"{entityType} '{entityDisplayName}'"
                : $"{entityType} (ID: {entityId})";

            switch (operation)
            {
                case EntityOperation.CREATE:
                    return $"New {displayText} has been created";
                case EntityOperation.UPDATE:
                    return $"{displayText} has been updated";
                case EntityOperation.DELETE:
                    return $"{displayText} has been deleted";
                default:
                    return $"{displayText} operation: {operation}";
            }
        }
    }
}
