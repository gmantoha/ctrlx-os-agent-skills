# REST API Access

Use REST for remote automation, integration, and browser or script-driven interactions. This is the preferred interface when setup or diagnostics must be automated from outside the device.

Good fits:

- CI scripts
- integration services
- browser clients
- external diagnostics tools

Prefer published Swagger/OpenAPI descriptions and verify authentication requirements before assuming an endpoint is callable.

Fetch the latest API documentation from the published docs when possible:

- https://boschrexroth.github.io/rest-api-description/index.html

If live access is unavailable, use the local fallback snapshot under `../../rest-api/openapi-snapshot/`.

Follow the Authentication Swagger/OpenAPI documentation for the target ctrlX OS version. Do not assume browser login, PLC calls, and remote scripts use the same authentication path.

On real devices, confirm before using REST calls that write persistent configuration.
