# Device Portal Template Integration

The Device Portal public API can create and apply ctrlX CORE templates for
external commissioning software. This reference is intentionally generic:
credentials, customer IDs, device IDs, hostnames, IP addresses, and raw setup
exports belong in a private project workspace, never in this skill.

## API-only authentication

Use a Keycloak/OIDC client-credentials token and the APIM subscription key. Do
not automate the browser portal or copy its session cookie into a service.
Cache one token until expiry, redact it in logs, and keep client secrets in a
secret manager or local untracked configuration.

## Endpoint families

Cloud API resources commonly used by the template workflow:

```text
GET  /devices/{deviceId}
GET  /devices/{deviceId}/setup/setupinfo
POST /tasks
GET  /tasks/{taskId}
GET  /templates/{templateId}
```

The exact public API version and availability of template listing or mutation
endpoints must be confirmed against the current released documentation. Do not
assume that the WebUI's same-origin BFF paths or cookies are valid for a service
account.

The target-device Setup API is separate:

```text
GET  https://<core>/setup/api/v1/setupinfo
POST https://<core>/setup/api/v1/apply   # multipart, mode=merge
GET  https://<core>/setup/api/v1/tasks
GET  https://<core>/setup/api/v1/tasks/<task-id>
```

## Template content model

The `setupInfo` object combines package metadata, system settings, and resource
references. The important distinction is:

- app package metadata alone does not contain the PLC boot project;
- `configurations.active` points to active app data, including PLC runtime data;
- the archive must contain the referenced files and the JSON must retain their
  `$path` reference;
- a full active configuration is a whole-solution unit unless the platform
  explicitly supports narrower app-data selection.

For a complete-device template, preserve the full source setupInfo and review
the resulting template before applying. For a modular PLC deployment, prefer a
direct, tested Setup ZIP if the active solution cannot be selected per app.

## PLC-specific verification

For a real PLC boot project, verify both artifacts in the active configuration:

```text
configurations/active/plc/run/linux-gcc-aarch64/data/Application.app
configurations/active/plc/run/linux-gcc-aarch64/data/Application.crc
```

The exact architecture path depends on the target. `Application.crc` must match
the application. Also verify `plc_system.cfg` and, where engineering or
diagnostic behavior matters, the project synchronization metadata.

## Template result is not device proof

The portal may return `DONE` even when a resource path was lost and the CORE
skipped the corresponding data. Always verify the target through the CORE:

- Setup task protocol says configurations were loaded;
- critical files exist and have expected hashes/sizes;
- PLC project information is readable;
- PLC cycle activity increases;
- unrelated installed apps and data match the intended policy.

See [`workflows/device-portal-templates.md`](../../../workflows/device-portal-templates.md)
for the complete decision flow, safety gate, payload shapes, and known failure
modes.
