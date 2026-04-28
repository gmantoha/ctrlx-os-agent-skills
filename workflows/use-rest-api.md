# Use REST API

Use this workflow when the caller is outside the device or when a published REST endpoint is the intended integration surface.

## Always Verify

- Authentication expectations.
- Endpoint version.
- Whether a Data Layer path would be a better in-device choice.
- Latest live OpenAPI documentation first, then `reference/rest-api/openapi-snapshot/` as fallback.

Treat only REST APIs documented in `https://github.com/boschrexroth/rest-api-description` as stable. Do not build workflows on reverse-engineered HTTP calls unless the user explicitly accepts the risk.

## Standard Flow

1. Determine external caller, target device, and desired operation.
2. Confirm authentication flow and permissions.
3. Find the documented endpoint and schema.
4. Prepare a minimal request example.
5. If executing against a real device, treat writes as persistent changes and ask first.
6. Verify the response and resulting device state.
