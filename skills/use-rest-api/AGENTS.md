# Use REST API Workflow

Use this workflow when the caller is outside the device or when a published REST endpoint is the intended integration surface.

Always verify:

- authentication expectations
- endpoint version
- whether a Data Layer path would be a better in-device choice
- latest live OpenAPI documentation first, then `shared/rest-api/openapi-snapshot/` as fallback

Treat only REST APIs documented in https://github.com/boschrexroth/rest-api-description as stable. Do not build workflows on reverse-engineered HTTP calls unless the user explicitly accepts the risk.
