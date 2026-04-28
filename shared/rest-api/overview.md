# REST API Overview

ctrlX publishes released REST APIs as OpenAPI descriptions.

Prefer the live published documentation when network access is available:

- https://boschrexroth.github.io/rest-api-description/index.html

Use the local snapshot in `openapi-snapshot/` as an offline fallback or when an agent needs a stable local copy of the latest known OpenAPI JSON files.

Only REST API descriptions published in the upstream `boschrexroth/rest-api-description` repository should be treated as stable for applications. Reverse-engineered HTTP calls or APIs outside that repository may change without notice.

OpenAPI generators can parse these specifications, but generated clients may still need manual adjustments and tests.
