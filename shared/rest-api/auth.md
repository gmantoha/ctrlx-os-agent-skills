# REST API Authentication

Authentication depends on the target service and deployment context.

Practical rule:

- do not assume the browser, PLC, and remote script use the same auth path
- prefer the platform's documented authentication flow for external clients
- avoid embedding credentials in examples unless they are documented public defaults for local labs
