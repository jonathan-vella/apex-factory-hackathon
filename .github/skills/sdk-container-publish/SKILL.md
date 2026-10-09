---
name: sdk-container-publish
description: Build Contoso University's container image with .NET SDK container publishing, without Docker or a Dockerfile, and push it to the private Azure Container Registry from vm-dev01. Use when packaging the app, when a push fails, or when someone suggests a Dockerfile.
---

# SDK container publishing

## When to use

- After task 07, to package the app (playbook step 4).
- When `dotnet publish /t:PublishContainer` or the push fails.
- When an agent proposes a `Dockerfile` or Docker Desktop: the kit uses neither, and `vm-dev01` has no Docker.

Scope: `app/ContosoUniversity` only.

## Steps

1. **Project properties.** Task 01 puts the image settings in `ContosoUniversity.csproj`, so nobody has to remember flags. Check them:

   | Property | Value |
   |---|---|
   | `ContainerBaseImage` | `mcr.microsoft.com/dotnet/aspnet:10.0` |
   | `ContainerRepository` | `contoso-university` |
   | `ContainerPort` item | `8080`, type `tcp`: the port .NET 10 images listen on, and the web app's `WEBSITES_PORT` |

   There's no `Dockerfile` or `.dockerignore`.

2. **Sign in to the registry.** The registry has no admin user and no public access, so use a token from your Azure CLI sign-in, on `vm-dev01`, where the registry name resolves to its private endpoint. The archetype gives you **AcrPush**.

   ```powershell
   Set-Location C:\src\<your-repo>\app\ContosoUniversity
   $token = az acr login --name cruniversity<suffix> --expose-token --only-show-errors | ConvertFrom-Json
   $env:DOTNET_CONTAINER_REGISTRY_UNAME = $token.username
   $env:DOTNET_CONTAINER_REGISTRY_PWORD = $token.accessToken
   ```

3. **Publish and push** in one step, with a new tag for every push:

   ```powershell
   dotnet publish -c Release /t:PublishContainer -p:ContainerRegistry=cruniversity<suffix>.azurecr.io -p:ContainerImageTag=<tag>
   Remove-Item Env:DOTNET_CONTAINER_REGISTRY_UNAME, Env:DOTNET_CONTAINER_REGISTRY_PWORD
   ```

## Checks

- `git ls-files app | Select-String Dockerfile` prints nothing.
- `az acr repository show-tags --name cruniversity<suffix> --repository contoso-university -o table` lists your tag.
- `Resolve-DnsName cruniversity<suffix>.azurecr.io` returns a `10.20.<n>.` address.

| Error | Cause |
|---|---|
| `unauthorized` or `CONTAINER1001` | The token expired (it lasts about 3 hours), or the variables aren't set in this terminal. Run step 2 again |
| The push times out | The registry name resolved to a public address: you aren't on `vm-dev01`, or its private DNS isn't linked |
| The base image can't be pulled | `vm-dev01` can't reach `mcr.microsoft.com` through the hub firewall |

## Example

Before, a `Dockerfile` an agent might suggest:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0
COPY ./publish /app
ENTRYPOINT ["dotnet", "/app/ContosoUniversity.dll"]
```

After, no Dockerfile. In `ContosoUniversity.csproj`:

```xml
<PropertyGroup>
  <ContainerBaseImage>mcr.microsoft.com/dotnet/aspnet:10.0</ContainerBaseImage>
  <ContainerRepository>contoso-university</ContainerRepository>
</PropertyGroup>
<ItemGroup>
  <ContainerPort Include="8080" Type="tcp" />
</ItemGroup>
```
