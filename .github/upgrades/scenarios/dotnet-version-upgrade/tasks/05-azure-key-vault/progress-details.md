# Task 05 progress details

## Outcome

- Added `Azure.Extensions.AspNetCore.Configuration.Secrets` 1.5.2. Existing `Azure.Identity` 1.21.0 is reused.
- Outside Development, `Program.cs` now requires `KeyVault:VaultUri`, validates an HTTPS standard `*.vault.azure.net` hostname with default port and root path, and rejects IP literals, `privatelink`, user info, query strings, and fragments.
- The application adds the Key Vault configuration provider with `DefaultAzureCredential` before reading `ConnectionStrings:DefaultConnection` or registering `SchoolContext`.
- Startup verifies that the Key Vault provider itself contains a non-empty `ConnectionStrings:DefaultConnection` value. The provider maps the existing secret name `ConnectionStrings--DefaultConnection`; a value from a lower-priority source cannot silently substitute for a missing vault secret.
- Missing or invalid vault settings and provider-load failures stop non-Development startup with a clear diagnostic. No secret value is logged, copied to source, or exposed in a client response.
- Development skips Key Vault setup and continues to use the unchanged `ConnectionStrings:DefaultConnection` user secret. Existing non-Development SQL authentication and private-endpoint validation remains unchanged.
- Added a concise runtime-configuration section to the app README. No vault, secret, identity, role, network setting, deployment, or on-premises resource was changed.

## Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --verbosity minimal`: restore and build succeeded with 0 warnings and 0 errors.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --configuration Release --verbosity minimal`: restore and build succeeded with 0 warnings and 0 errors.
- Package resolution confirmed `Azure.Extensions.AspNetCore.Configuration.Secrets` 1.5.2 and `Azure.Identity` 1.21.0.
- Compiler diagnostics found no errors in the modified project/startup files; `git diff --check` found no whitespace errors (Git emitted only existing CRLF-to-LF notices).
- Production startup checks rejected both a missing `KeyVault:VaultUri` and an invalid HTTP URI before SQL connection-string validation; these checks made no Azure request.
- In Development with `KeyVault:VaultUri` absent, the application used the existing user-secret configuration and returned HTTP 200 for `/`, `/Students`, `/Courses`, `/Instructors`, and `/Departments`.
- Test-project discovery returned `[]`; no applicable .NET test project exists.
- The user-secrets check printed key names only. `ConnectionStrings:DefaultConnection` was present; no Key Vault setting was present. No secret values were inspected or printed.

## External integration boundary

- A live Key Vault load could not be performed because no `KeyVault:VaultUri` is configured locally. The vault's existence, secret value, private DNS/network reachability, `DefaultAzureCredential` identity resolution, and secret-list/read permissions remain unverified external dependencies.
- The non-Development path must be validated in the existing Azure environment after its owner supplies the standard vault hostname and ensures the existing `ConnectionStrings--DefaultConnection` secret and access are available. No Azure or network changes were made for this task.

## Files changed

- `.github/upgrades/scenarios/dotnet-version-upgrade/scenario-instructions.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/05-azure-key-vault/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/05-azure-key-vault/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/README.md`

## Boundary

Task 05 is complete for application code and local validation. Live Key Vault access remains externally unverified as recorded above. Task 06, OpenTelemetry with Azure Monitor, remains unstarted for review and separate approval.