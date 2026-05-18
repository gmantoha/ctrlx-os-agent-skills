# Service vs Operation Mode

ctrlX CORE has three operating modes: **OPERATION**, **SETUP**, and **SERVICE**.

## When Each Mode Is Required

- **OPERATION** — normal production use.
- **SETUP** — initial device configuration.
- **SERVICE** — required for app installation and updates. Must be set before uploading packages.

## Reading the Current Mode

```
GET /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate
```

The current mode is in `response.value.state`.

## Setting the Mode

```
PUT /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate
```

Body:

```json
{"type":"object","value":{"state":"SERVICE"}}
```

Replace `SERVICE` with `OPERATION` or `SETUP` as needed.

## Rules

- Always read and store the current mode before switching.
- Restore the original mode after maintenance tasks complete.
- Do not switch a productive system to SERVICE mode without user confirmation.
