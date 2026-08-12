# ctrlX Snap Build and Install Loop

Use this recipe for a web HMI or service developed on Windows, built with
Snapcraft, and installed as a snap on ctrlX CORE.

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

## Release boundary

`grade: devel` is suitable for development installs but is not a finished
store/release package. Production work still needs final technical naming,
signing/release metadata, trusted TLS/authentication policy, and a documented
configuration strategy. Keep CORE URLs, certificate behavior, credentials, and
data paths environment-configurable; never embed a developer machine path or
secret in the snap.
