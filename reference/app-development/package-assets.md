# Package Assets

Package assets integrate a snap into ctrlX OS through package metadata such as permissions, menus, reverse proxy mappings, documentation links, configuration handling, certificate stores, licenses, and UI extensions.

Primary source: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/package-assets.html

## Source Rules

- Check the live SDK Package Assets page before relying on local examples.
- Use the schema URL from the official docs or the target ctrlX OS version.
- Keep manifests minimal; do not declare menus, scopes, licenses, or certificate stores that the app does not use.

## File Location

The package manifest belongs below:

```text
configs/package-assets/<snap-name>.package-manifest.json
```

The manifest `id` should match the technical app/snap name.

## snapcraft Integration

Provide package assets through a `configs` part and `package-assets` slot:

```yaml
parts:
  configs:
    plugin: dump
    source: ./configs
    organize:
      'package-assets/*': package-assets/${CRAFT_PROJECT_NAME}/

slots:
  package-assets:
    interface: content
    content: package-assets
    source:
      read:
        - $SNAP/package-assets/${CRAFT_PROJECT_NAME}

apps:
  app:
    slots:
      - package-assets
```

This matches the current `core24` Python webserver sample. The Package Assets
guide also contains older examples using `SNAPCRAFT_PROJECT_NAME`; use the
variable expected by the selected sample and Snapcraft version, and keep the
organize destination and slot source identical.

## Common Manifest Capabilities

- `scopes-declaration`: declares permissions administrators can assign.
- `services.proxyMapping`: maps external web paths to an app web server.
- `menus.sidebar`, `menus.settings`, `menus.overview`: integrates navigation entries.
- `commands.activeConfiguration`: registers Solutions save/load callbacks.
- `configuration.appDirectories`: declares app configuration directories.
- `certificatestores`: declares certificate stores managed by the platform.
- `licenses`: declares supported or required licenses.
- `uiExtensions.dashboard`: declares dashboard widgets.

## Scopes

Scope naming follows the official package-assets guidance:

```text
<id>.<service>.<scope_name>.<access>
```

Common access suffixes are `r`, `w`, `rw`, and `x`. Services should also honor the administrative scope `rexroth-device.all.rwx` where appropriate.

## Reverse Proxy

Prefer Unix sockets over TCP ports for app web services.

```json
{
  "services": {
    "proxyMapping": [
      {
        "name": "ctrlx-mycompany-myapp.web",
        "url": "/ctrlx-mycompany-myapp/",
        "binding": "unix://{$SNAP_DATA}/package-run/ctrlx-mycompany-myapp/web.sock",
        "restricted": ["/ctrlx-mycompany-myapp/api/v1"]
      }
    ]
  }
}
```

Important details:

- `services.proxyMapping.name` must be unique. Current official examples use
  both the snap id and `<id>.<service>` forms, so do not derive it from the
  `apps.<daemon>` key or impose one unsupported naming form.
- Package-manifest environment variables use `{$VAR}`, not `${VAR}`.
- Unix socket paths are limited by the Linux socket path length, commonly 108 characters.
- The app must create and remove its own socket file.
- Restrict API routes that require authenticated access.
- Keep the manifest binding, launcher socket path, and `package-run` source
  directory identical after variable expansion.

Expose the runtime socket directory with `package-run` when using Unix sockets:

```yaml
slots:
  package-run:
    interface: content
    content: package-run
    source:
      write:
        - $SNAP_DATA/package-run/${CRAFT_PROJECT_NAME}

apps:
  app:
    slots:
      - package-run
```

## Minimal Manifest Shape

Use this as a starting shape only; verify fields against the live schema.

```json
{
  "$schema": "https://json-schema.boschrexroth.com/ctrlx-automation/ctrlx-os/apps/package-manifest/package-manifest.v1.4.schema.json",
  "version": "1.0.0",
  "id": "ctrlx-mycompany-myapp",
  "scopes-declaration": [],
  "services": {
    "proxyMapping": []
  },
  "menus": {
    "sidebar": []
  }
}
```
