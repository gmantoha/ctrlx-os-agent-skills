# ctrlX Snap Build and Install Loop

Use this recipe for a web HMI or service developed on Windows, built with
Snapcraft, and installed as a snap on ctrlX CORE.

## Fast path

- Local preview or source-only work does not need the ABE.
- For an installable snap, start the configured ctrlX WORKS ABE directly when
  it is not already online; do not wait for the user to start it.
- Confirm SSH and `snapcraft --version`, synchronize the canonical source once,
  build the requested architecture once, inspect and smoke-test that artifact,
  then stop the temporary ABE.
- Keep ARM64 as the active build target until the physical deployment works;
  defer AMD64 rather than building both by default.

## Keep three locations distinct

Use one source of truth:

```text
Windows source:      C:\Users\<user>\source\repos\<app>
ABE Linux build:     /home/<user>/<app>
Windows artifacts:   C:\Users\<user>\source\repos\<app>-artifacts
```

Edit the Windows source, copy or sync it into the App Build Environment (ABE),
and copy only completed `.snap` files back to the artifacts folder. Do not edit
the Windows and ABE copies independently. Keep generated build directories and
snap files out of source control.

## App Build Environment

The ABE is a Linux VM managed by ctrlX WORKS. It is the reproducible place for
Snapcraft builds; it does not need to run when no build or SSH session is
active.

Use the official SDK setup for the selected SDK/OS version, then load the
environment before building:

```bash
source /etc/environment
```

When ctrlX WORKS forwards SSH from Windows, the direction is normally:

```text
Windows 127.0.0.1:10022 -> ABE port 22
```

Run SSH/SCP to `127.0.0.1:10022` from Windows. From inside the VM,
`127.0.0.1:10022` refers back to the VM and is not the Windows forwarding
endpoint. Use the actual forwarded port if ctrlX WORKS is configured
differently.

VS Code is useful for editing the canonical source and optionally for Remote
SSH observation. The ABE terminal is the authoritative environment for
Snapcraft and Linux packaging; VS Code is not a substitute for the ABE.

## Build

Confirm the version, target architecture, base, confinement, package-assets,
and package-run declarations before starting. Build only the architectures
that match the deployment targets:

```bash
cd ~/<app>
snapcraft pack --build-for=amd64 --destructive-mode --verbosity=verbose
snapcraft pack --build-for=arm64 --destructive-mode --verbosity=verbose
```

`amd64` is typical for an x86 virtual CORE; physical CORE hardware is commonly
`arm64`. Verify the target rather than assuming. If switching architectures
causes stale parts, clean the relevant Snapcraft parts before rebuilding.

When one target architecture is not yet working, freeze the other architecture:
build and deploy only the target architecture until it has passed the target
smoke test. Do not use a successful amd64 virtual build as evidence that the
arm64 physical package is valid. For a physical ARM64 target, the focused
command is:

```bash
snapcraft pack --build-for=arm64 --destructive-mode --verbosity=verbose
```

After each build, inspect the package before installation:

```bash
snap info ./<app>_1.0.0_amd64.snap
unsquashfs -l ./<app>_1.0.0_amd64.snap
python3 -m json.tool configs/package-assets/<snap-name>.package-manifest.json
```

Confirm the snap architecture, version, launcher, package manifest, web assets,
and Unix-socket paths. Bump the application version for an update so the target
does not confuse a new package with an already installed one.

## Web snap integration checks

- The package manifest `id`, public URL, launcher, and socket path must agree.
- `services.proxyMapping.name` is a unique web-service identifier in
  `<id>.<service>` form, commonly `<snap-name>.web`; it does not have to equal
  the `apps.<daemon>` key.
- Package-manifest variables use `{$SNAP_DATA}`, not shell-style `${SNAP_DATA}`.
- The launcher must create/remove the socket at the exact path published by the
  manifest and exposed through `package-run`.
- Keep Unix socket paths below the Linux path-length limit.
- Prefer the official package-assets schema for the target ctrlX OS release.

For a confined web daemon, declare `network` and `network-bind` when the
server must bind/listen. The official ctrlX Python web-server pattern uses
`network-bind`; omitting it can leave the daemon unable to create a usable
upstream even though the manifest is correct.

Keep a core24 Python launcher simple and Linux-native:

```sh
#!/bin/sh
set -eu
exec python3 "$SNAP/server.py"
```

The launcher must be LF-only and executable. A CRLF shell launcher can fail
with `cannot execute: required file not found`. Do not assume
`$SNAP/usr/bin/python3` exists; core24 provides `python3` through the base
runtime's `PATH`.

## Windows host and ctrlX WORKS details

When Snapcraft, Docker, or a usable WSL distribution is not available on
Windows, use the configured ctrlX WORKS ABE instead of trying to assemble a
second ad-hoc build environment. The installed builder launcher commonly uses
relative cloud-image, overlay, and user-data paths, so start it with the ABE
instance directory as its working directory. A typical Windows forwarding is:

```text
Windows 127.0.0.1:10022 -> ABE SSH port 22
```

Wait for an actual SSH banner/login, not only an open TCP port. A VM can accept
the forwarded port before sshd is ready. Then validate the toolchain:

```powershell
ssh -p 10022 <abe-user>@127.0.0.1 "printf ABE_OK && snapcraft --version"
```

Each SSH/SCP invocation can create a transient `session-<number>.scope` entry
in the ABE. These are host login sessions, not an app-created restart loop;
they stop when the connection closes.

`snapcraft pack --destructive-mode` may print a warning about running as a
non-super user. Treat the process exit code and produced `.snap` as the
authoritative result; do not convert a warning on stderr into a build failure.
Stop the temporary ABE VM after the build unless it is intentionally being
used for another independent task.

Build preserved HMI variants in separate remote directories and download each
artifact to a distinct Windows folder. Package names, public routes, socket
directories, and manifests must remain aligned; never synchronize one variant
over the other or treat an older same-version artifact as evidence of a fresh
build. Record a source revision, build environment, package metadata, and
SHA-256 for release handoff.

For example, two preserved variants used distinct technical identities:
`smart-hmi` with `/smart-hmi/` and `axis-hmi` with `/axis-hmi/`. The visible
product title may be the same, but the snap name, manifest `id`, proxy mapping,
launcher, package-run directory, and artifact path must not collide.

The public `vitalisAutomation/kuschke-silas-bachelor-thesis` repository is a
useful secondary example for this situation. Its `sdk-vm-automation` area
shows a Windows-driven SDK VM setup, while `crosscompiling/build-snap-amd64.sh`
and `build-snap-arm64.sh` show architecture-specific CMake build-kit
selection. Use it as an implementation reference only: official ctrlX SDK
documentation remains authoritative, and its scripts may install QEMU,
request administrator rights, use a proxy, or create VM state. Inspect before
running and do not copy generated VM images, keys, credentials, or local paths
into an application or this skill.

## Packaged launcher smoke test

Before installing, extract or otherwise run the exact built snap in the ABE
with temporary `SNAP` and `SNAP_DATA` directories. Confirm that:

1. the launcher starts without an interpreter/path error;
2. the daemon creates the exact Unix socket published by the manifest;
3. the socket is reachable with `curl --unix-socket`;
4. the public route returns HTTP 200 and contains the expected app shell.

This catches launcher, Python-path, socket, and asset errors without issuing
commands to a CORE. It does not replace target-side service, interface, base,
or confinement verification.

## Install and verify

Test on a matching virtual CORE first. For a real CORE, inspect first and get
explicit confirmation before installing, updating, restarting, or changing
device state.

For a local development snap in the ctrlX OS Web UI:

1. Go to **Settings -> Apps**.
2. Enable installation from an unknown source if the policy requires it.
3. Switch to **Service Mode**.
4. Choose **Install from file** and select the matching `.snap`.
5. Return to Operation Mode only after the install completes.

Verify the installed package, daemon, interfaces, logs, and web route:

```bash
snap list <snap-name>
snap services <snap-name>
snap connections <snap-name>
sudo snap logs <snap-name> -n 100
```

For an unavailable web app, inspect the package-assets registration, menu URL,
proxy mapping name, package-run connection, socket existence, and daemon logs
before rebuilding. Do not assume that a browser symptom identifies the failed
layer.

The generic CORE page "Waiting for app to start" or a direct `502` means the
public route is registered but the reverse proxy cannot reach a healthy
upstream. It can be caused by a crashed daemon, missing socket,
`package-run`/plug state, base incompatibility, or confinement. Check the
installed version, `snap services`, `snap connections`, exact socket path, and
`snap logs` separately.

Do not interpret the following as a license failure:

- a source-code license such as MIT in project metadata;
- a missing FOSS notice;
- a package `license` field in `snapcraft.yaml`.

The package manifest `licenses` array is for ctrlX device capability identifiers
such as `SWL-...`; `required: true` means the capability license is mandatory.
Declare it only when the app actually uses the License Manager API.

## Release boundary

`grade: devel` is suitable for development installs but is not a finished
store/release package. Production work still needs final technical naming,
signing/release metadata, trusted TLS/authentication policy, and a documented
configuration strategy. Keep CORE URLs, certificate behavior, credentials, and
data paths environment-configurable; never embed a developer machine path or
secret in the snap.
