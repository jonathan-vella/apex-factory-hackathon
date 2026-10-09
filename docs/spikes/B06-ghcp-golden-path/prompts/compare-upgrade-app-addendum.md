Owner decisions for this run. Apply them together with the instructions above; where they're more specific, they take precedence.

- The application has no Web API or OData surface. The notification JSON endpoints are consumed only by the application's own `notifications.js`. Preserve their routes, HTTP methods and JSON shape. Don't use the `migrating-webapi-odata` skill, and don't run its compatibility gate.
- An interim in-process notification queue is acceptable until Task 4. Don't move Service Bus into Task 1.
- Do no work outside the seven tasks. Record any extra finding as a recommendation only; don't add, split or implement tasks for it.
- Limit validation to `app/ContosoUniversity`: build, run and test only that project. Don't run the repository's PowerShell or npm checks.
- Local validation uses the `ConnectionStrings:DefaultConnection` user secret. Never fall back to LocalDB.
- Local validation runs on vm-dev01, inside the spike's virtual network: private DNS resolves every backend's standard host name to its private endpoint, and DefaultAzureCredential uses the owner's Azure CLI sign-in on the VM. Blob, Service Bus and Key Vault checks are therefore expected to run, not to be blocked.
