using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using ContosoUniversity.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Services
{
    public class NotificationService : IAsyncDisposable
    {
        private const int MaxReceiveCount = 10;
        private static readonly TimeSpan MaxWait = TimeSpan.FromSeconds(1);

        private readonly ServiceBusClient _client;
        private readonly ServiceBusSender _sender;
        private readonly ServiceBusReceiver _receiver;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(IConfiguration configuration, ILogger<NotificationService> logger)
        {
            _logger = logger;

            var fullyQualifiedNamespace = configuration["ServiceBus:FullyQualifiedNamespace"];
            var queueName = configuration["ServiceBus:QueueName"];
            if (string.IsNullOrWhiteSpace(fullyQualifiedNamespace) || string.IsNullOrWhiteSpace(queueName))
            {
                throw new InvalidOperationException(
                    "ServiceBus:FullyQualifiedNamespace and ServiceBus:QueueName must be configured (user secrets in Development, environment variables or app settings elsewhere).");
            }

            _client = new ServiceBusClient(fullyQualifiedNamespace, new DefaultAzureCredential());
            _sender = _client.CreateSender(queueName);
            // ReceiveAndDelete mirrors the destructive MSMQ receive.
            _receiver = _client.CreateReceiver(queueName, new ServiceBusReceiverOptions
            {
                ReceiveMode = ServiceBusReceiveMode.ReceiveAndDelete
            });
        }

        public void SendNotification(string entityType, string entityId, EntityOperation operation, string userName = null)
        {
            SendNotification(entityType, entityId, null, operation, userName);
        }

        public void SendNotification(string entityType, string entityId, string entityDisplayName, EntityOperation operation, string userName = null)
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
                _sender.SendMessageAsync(message).GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                // Never break the main operation.
                _logger.LogError(ex, "Failed to send notification for {EntityType} {EntityId}", entityType, entityId);
            }
        }

        public IList<Notification> ReceiveNotifications()
        {
            var result = new List<Notification>();
            var messages = _receiver.ReceiveMessagesAsync(MaxReceiveCount, MaxWait).GetAwaiter().GetResult();
            foreach (var message in messages)
            {
                try
                {
                    result.Add(JsonSerializer.Deserialize<Notification>(message.Body.ToString()));
                }
                catch (JsonException ex)
                {
                    _logger.LogWarning(ex, "Skipping a notification message that is not valid JSON");
                }
            }

            return result;
        }

        public void MarkAsRead(int notificationId)
        {
            // Notifications are removed on receive; nothing to persist.
        }

        public async ValueTask DisposeAsync()
        {
            await _sender.DisposeAsync();
            await _receiver.DisposeAsync();
            await _client.DisposeAsync();
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
