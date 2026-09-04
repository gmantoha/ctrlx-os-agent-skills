# Snap Packaging

ctrlX apps are snaps. Start with the official SDK setup and samples before adapting local fallback snippets.

Primary sources:

- SDK setup: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/setup_overview.html
- SDK GitHub repository: https://github.com/boschrexroth/ctrlx-automation-sdk
- SDK samples: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/samples.html
- Snapcraft reference: https://snapcraft.io/docs/snapcraft-yaml-reference

## Standard Flow

1. Identify the app type: web UI, service, Data Layer client, Data Layer provider, or mixed app.
2. Identify the target architecture: `amd64`, `arm64`, or both.
3. Check the current SDK docs and closest official sample for the
   language/runtime, target base, and `platforms` declaration.
4. Keep `snapcraft.yaml` minimal and add only interfaces that the app actually uses.
5. Build in a ctrlX App Build Environment when available, or document why native/destructive builds are used.
6. Verify snap metadata and contents before device installation.

## Common ctrlX Snap Elements

Typical production app metadata includes:

```yaml
confinement: strict
grade: stable
base: core24
type: app
```

The current SDK Python webserver sample uses `base: core24` and declares both
targets explicitly:

```yaml
platforms:
  amd64:
  arm64:
    build-on: [amd64, arm64]
    build-for: [arm64]
```

Treat this as a current sample, not a universal compatibility promise. Match
the base and platforms to the target ctrlX OS release and the selected SDK
sample.

For daemon services, define an app command and explicit plugs:

```yaml
apps:
  app:
    command: bin/myapp
    daemon: simple
    restart-condition: always
    plugs:
      - network
      - network-bind
```

Add ctrlX-specific content interfaces only when needed:

- `package-assets` for package manifest, translations, and OSS metadata.
- `package-run` for reverse-proxy Unix socket access.
- `datalayer` for in-device Data Layer access.
- `active-solution` for Solutions active configuration storage.
- `licensing-service` for license acquisition.

## Build Environment Checks

The official SDK setup scripts are preferred. If diagnosing local builds, these packages commonly matter for Data Layer builds:

```bash
sudo apt-get update && sudo apt-get install -y \
    snapcraft \
    pkg-config \
    libsystemd-dev \
    libzmq3-dev \
    gcc \
    gcc-aarch64-linux-gnu
```

Language-specific SDK setup may also be required. Check the SDK `scripts/` directory and official setup pages first.

## Build And Inspect

Common local commands:

```bash
snapcraft clean
snapcraft pack --build-for=<amd64-or-arm64> --verbosity=verbose
snap info ./my-app_1.0.0_<target-architecture>.snap
unsquashfs -l ./my-app_1.0.0_<target-architecture>.snap
```

This follows the official architecture build scripts: clean, then pack one
target. Use `--destructive-mode` only deliberately outside the normal ABE
flow; it builds directly on and can modify the host environment.

## Deployment Safety

Installing, updating, removing, restarting, or reconfiguring apps on a real ctrlX device is a persistent change. Inspect first and ask for confirmation before changing the device.
