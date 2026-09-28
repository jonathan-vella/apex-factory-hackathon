#nullable enable

using System;
using System.Diagnostics;
using System.Net;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using ContosoUniversity.Models;
using Microsoft.Extensions.Configuration;

namespace ContosoUniversity.Services
{
    public sealed class NotificationService : INotificationService, IAsyncDisposable
    {
        private const string NamespaceConfigurationKey = "ServiceBus:FullyQualifiedNamespace";
        private const string QueueConfigurationKey = "ServiceBus:QueueName";
        private readonly Lazy<ServiceBusClients> serviceBusClients;
        private readonly SemaphoreSlim receiveGate = new(1, 1);

        public NotificationService(IConfiguration configuration)
        {
            serviceBusClients = new Lazy<ServiceBusClients>(
                () => CreateServiceBusClients(configuration),
                LazyThreadSafetyMode.ExecutionAndPublication);
        }

        public Task SendNotificationAsync(
            string entityType,
            string entityId,
            EntityOperation operation,
            string? userName = null,
            CancellationToken cancellationToken = default)
        {
            return SendNotificationAsync(entityType, entityId, null, operation, userName, cancellationToken);
        }

        public async Task SendNotificationAsync(
            string entityType,
            string entityId,
            string? entityDisplayName,
            EntityOperation operation,
            string? userName = null,
            CancellationToken cancellationToken = default)
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
                ContentType = "application/json",
                Subject = $"{entityType} {operation}"
            };
            message.ApplicationProperties["priority"] = "Normal";

            await serviceBusClients.Value.Sender.SendMessageAsync(message, cancellationToken);
        }

        public async Task<Notification?> ReceiveNotificationAsync(CancellationToken cancellationToken = default)
        {
            await receiveGate.WaitAsync(cancellationToken);
            try
            {
                var receiver = serviceBusClients.Value.Receiver;
                var message = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(1), cancellationToken);
                if (message == null)
                {
                    return null;
                }

                await receiver.CompleteMessageAsync(message, cancellationToken);
                try
                {
                    return JsonSerializer.Deserialize<Notification>(message.Body.ToString());
                }
                catch (JsonException exception)
                {
                    Debug.WriteLine($"Failed to deserialize notification: {exception.Message}");
                    return null;
                }
            }
            catch (ServiceBusException exception) when (exception.Reason == ServiceBusFailureReason.ServiceTimeout)
            {
                return null;
            }
            finally
            {
                receiveGate.Release();
            }
        }

        public void MarkAsRead(int notificationId)
        {
        }

        public async ValueTask DisposeAsync()
        {
            if (serviceBusClients.IsValueCreated)
            {
                await serviceBusClients.Value.DisposeAsync();
            }

            receiveGate.Dispose();
        }

        private static ServiceBusClients CreateServiceBusClients(IConfiguration configuration)
        {
            var fullyQualifiedNamespace = configuration[NamespaceConfigurationKey];
            var queueName = configuration[QueueConfigurationKey];
            if (string.IsNullOrWhiteSpace(fullyQualifiedNamespace) || string.IsNullOrWhiteSpace(queueName))
            {
                throw new InvalidOperationException(
                    "ServiceBus:FullyQualifiedNamespace and ServiceBus:QueueName are required for notification operations.");
            }

            if (!IsValidNamespace(fullyQualifiedNamespace) ||
                queueName != queueName.Trim() ||
                queueName.Contains('/') ||
                queueName.Contains('\\'))
            {
                throw new InvalidOperationException(
                    "Service Bus must use a standard private-DNS namespace hostname and a single queue name.");
            }

            var client = new ServiceBusClient(fullyQualifiedNamespace, new DefaultAzureCredential());
            var sender = client.CreateSender(queueName);
            var receiver = client.CreateReceiver(queueName, new ServiceBusReceiverOptions
            {
                ReceiveMode = ServiceBusReceiveMode.PeekLock
            });

            return new ServiceBusClients(client, sender, receiver);
        }

        private static bool IsValidNamespace(string fullyQualifiedNamespace)
        {
            return Uri.TryCreate($"https://{fullyQualifiedNamespace}", UriKind.Absolute, out var namespaceUri) &&
                namespaceUri.IsDefaultPort &&
                string.Equals(namespaceUri.AbsolutePath, "/", StringComparison.Ordinal) &&
                string.IsNullOrEmpty(namespaceUri.UserInfo) &&
                string.IsNullOrEmpty(namespaceUri.Query) &&
                string.IsNullOrEmpty(namespaceUri.Fragment) &&
                string.Equals(namespaceUri.Host, fullyQualifiedNamespace, StringComparison.OrdinalIgnoreCase) &&
                !IPAddress.TryParse(namespaceUri.Host, out _) &&
                namespaceUri.Host.EndsWith(".servicebus.windows.net", StringComparison.OrdinalIgnoreCase) &&
                !namespaceUri.Host.Contains("privatelink", StringComparison.OrdinalIgnoreCase);
        }

        private static string GenerateMessage(
            string entityType,
            string entityId,
            string? entityDisplayName,
            EntityOperation operation)
        {
            var displayText = !string.IsNullOrWhiteSpace(entityDisplayName)
                ? $"{entityType} '{entityDisplayName}'"
                : $"{entityType} (ID: {entityId})";

            return operation switch
            {
                EntityOperation.CREATE => $"New {displayText} has been created",
                EntityOperation.UPDATE => $"{displayText} has been updated",
                EntityOperation.DELETE => $"{displayText} has been deleted",
                _ => $"{displayText} operation: {operation}"
            };
        }

        private sealed class ServiceBusClients : IAsyncDisposable
        {
            public ServiceBusClients(ServiceBusClient client, ServiceBusSender sender, ServiceBusReceiver receiver)
            {
                Client = client;
                Sender = sender;
                Receiver = receiver;
            }

            public ServiceBusClient Client { get; }
            public ServiceBusSender Sender { get; }
            public ServiceBusReceiver Receiver { get; }

            public async ValueTask DisposeAsync()
            {
                await Receiver.DisposeAsync();
                await Sender.DisposeAsync();
                await Client.DisposeAsync();
            }
        }
    }
}
