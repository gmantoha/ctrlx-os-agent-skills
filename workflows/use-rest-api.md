# Use REST API

Use this workflow when the caller is outside the device or when a published REST endpoint is the intended integration surface.

## Always Verify

- Authentication expectations.
- Endpoint version.
- Whether a Data Layer path would be a better in-device choice.
- Latest live OpenAPI documentation first, then `reference/rest-api/openapi-snapshot/` as fallback.

For device-side REST APIs, treat only APIs documented in `https://github.com/boschrexroth/rest-api-description` as stable. For cloud Device Portal APIs, use the official Device Portal developer portal's operation contract instead. Do not build workflows on reverse-engineered HTTP calls unless the user explicitly accepts the risk.

For Device Portal display-name changes, use `recipes/device-portal/update-device-name.md`.
The public Licensing API changes cloud metadata, not the CORE hostname. It is
verified on QA as of 2026-11-11; do not infer PROD acceptance from QA success or
mistake an invalid subscription key for a missing feature.

## Standard Flow

1. Determine external caller, target device, and desired operation.
2. Confirm authentication flow and permissions.
3. Find the documented endpoint and schema.
4. Prepare a minimal request example.
5. If executing against a real device, treat writes as persistent changes and ask first.
6. Verify the response and resulting device state.
