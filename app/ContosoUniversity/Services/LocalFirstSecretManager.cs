using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Security.KeyVault.Secrets;

namespace ContosoUniversity.Services;

// Optionally skips the vault's DefaultConnection so a local (Development) connection string is not replaced.
public sealed class LocalFirstSecretManager : KeyVaultSecretManager
{
    private const string ConnectionSecretName = "ConnectionStrings--DefaultConnection";
    private readonly bool _skipConnection;

    public LocalFirstSecretManager(bool skipConnection) => _skipConnection = skipConnection;

    public override bool Load(SecretProperties secret) =>
        !(_skipConnection && string.Equals(secret.Name, ConnectionSecretName, System.StringComparison.OrdinalIgnoreCase));
}
