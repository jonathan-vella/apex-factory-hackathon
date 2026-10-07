using './main.bicep'

// Values come from the environment (azd env or process); preflight derives everything except suffix.
param suffix = readEnvironmentVariable('SUFFIX')
param tenantId = readEnvironmentVariable('AZURE_TENANT_ID')
param location = readEnvironmentVariable('AZURE_LOCATION')
param logAnalyticsWorkspaceId = readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_ID')
param sqlMiDirectoryIdentityId = readEnvironmentVariable('SQLMI_DIRECTORY_IDENTITY_ID')
param deployerObjectId = readEnvironmentVariable('DEPLOYER_OBJECT_ID')
param deployerPrincipalName = readEnvironmentVariable('DEPLOYER_UPN')
param containerImage = readEnvironmentVariable('CONTAINER_IMAGE', 'mcr.microsoft.com/dotnet/samples:aspnetapp-10.0')
