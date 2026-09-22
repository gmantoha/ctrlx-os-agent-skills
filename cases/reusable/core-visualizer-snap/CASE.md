# Case: CORE Visualizer ARM64 web snap

## Use When

Use this case when building a small ctrlX CORE web HMI from Windows, packaging
it as a Python snap, and validating it on a physical ARM64 CORE. It combines
independent Motion discovery, PLC status adaptation, subscription-driven data,
safe command handling, package-assets integration, and the Windows-to-ABE
build/deploy loop.

## Problem

A clean axis HMI was required without adapting an existing smart-HMI. The
browser needed live Motion and PLC data, verified engineering units and
diagnostics, and guarded controls. The final web server had to run behind the
ctrlX OS reverse proxy as a strict-confinement snap on a physical ARM64 CORE.

The first installed package showed the generic CORE page saying that the app
was still being initialized. A license prompt was also present because source
code licensing metadata had been incorrectly put into the ctrlX device-license
field.

## Verified Core Visualizer facts

- The verified physical-CORE package is ARM64 snap `0.1.7`; the target was
  updated through the Package Manager REST API and returned to OPERATING mode.
- The target publishes two Motion axes:
  `GET /automation/api/v2/nodes/motion/axs?type=browse` returns `Axis_1` and
  `Axis_2`.
- Opening the app through the CORE portal requires no second sign-in. The
  portal cookie is exchanged server-side, while direct access without that
  portal session remains explicitly unauthenticated.
- Installed operation is local-only: no cloud or Internet service is needed
  for authentication exchange, Motion reads, or the Data Layer event stream.
- Axis discovery starts with a read-only snapshot and the live view uses the
  documented REST SSE subscription. The verified Axis_1 stream returned its
  initial snapshot event.
- The implementation stays intentionally small: Python standard-library
  backend, plain HTML/CSS/JavaScript frontend, a Unix socket, and one
  package-assets route. `README.md`, focused tests, and this case document the
  route, authentication, Motion, PLC, and subscription contracts.

## Verified Architecture

### Browser and authentication

- Keep the CORE host, username, password, and bearer token on the server.
- Return only an opaque `HttpOnly` session cookie to the browser.
- Do not put credentials or CORE tokens in browser storage, HTML, JavaScript,
  URLs, audit entries, or snap metadata.
- When the snap is opened through the CORE portal, use the forwarded
  `CTRLX-OS-SESSION-ID` cookie and exchange it server-side through Identity
  Manager. The cookie name may be dynamic
  (`CTRLX-OS-SESSION-ID-<id>`); preserve the original name/value pair instead
  of reconstructing a fixed cookie name. Use `https://localhost` for the
  installed backend's local CORE target.
- Derive installed browser API and SSE URLs from the module URL so a public
  prefix such as `/core-visualizer/` is retained. A root `/api/...` request
  can return the portal's HTTP 200 HTML and look like an empty JSON result.
- Keep the installed path local-only: no cloud or Internet dependency is
  needed for the portal session exchange, Motion reads, or Data Layer event
  stream. The local preview may retain explicit username/password login.
- Use the local preview on loopback and keep TLS verification configurable for
  self-signed lab certificates only.

### Motion and PLC contracts

- Browse the independent Motion tree at `/motion/axs`.
- Populate the axis selector only from currently returned axis names.
- Re-browse on refresh and when the selected axis changes; deleted axes must
  disappear and newly published names must appear.
- Never invent a numeric axis, use a default index, or convert a Motion name
  into a PLC array index.
- Browse the PLC symbol tree separately. Map a PLC record to Motion only through
  a published identity field such as `Admin.Name`.
- Treat absent, unreadable, invalid, or type-incompatible fields as
  `Unavailable`. A published numeric zero is valid data.

### Values, units, and diagnostics

- Show actual position, velocity, acceleration, power/enabled state,
  PLCopen/operational state, limits, engineering units, and diagnostics only
  when their published values are verified.
- Decode typed IEC enum objects such as
  `{"CXA_CommonTypes.ERROR_CODE":"RESOURCE_ERROR"}` before rendering. Direct
  JavaScript coercion produces `[object Object]`.
- Keep Motion alarms, current PLC status, and retained PLC diagnostic records
  separate.
- A retained diagnostic code or message is not an active alarm. Current alarm
  state must come from current Motion/PLC signals such as error level,
  `ERRORSTOP`, `HasError`, or `ErrorStop`.
- Diagnostics are per-axis. An error on one axis must not mark every axis as
  faulty.
- Read-only system health cards may use verified OS APIs such as
  `/system/api/v1/cpu` and `/system/api/v1/sensors`; unknown temperature
  sensors remain unavailable rather than being guessed.

### Data Layer subscriptions

- Use the documented REST events endpoint:
  `/automation/api/v2/events?nodes=...&publishIntervalMs=...`.
- Keep a small state/power sentinel subscription for the selected axis.
- Arm the value subscription as soon as powered state is verified, including
  powered standstill; do not wait for movement.
- Keep the value subscription through standstill and movement. Release it only
  after confirmed unpowered state or disconnect.
- Merge node-bearing events into the displayed model. An event without a usable
  node requires an explicit snapshot refresh.
- Do not subscribe to command nodes in the normal value stream.
- Bound queues and close all subscriptions on axis changes, logout, browser
  disconnect, and session expiry.
- Do not replace the event stream with a permanent browser timer or poll an
  unavailable capability.

### Local preview and editing

- Keep the UI as plain `web/index.html`, `web/styles.css`, and `web/app.js`
  unless a dependency is required by the project.
- Start the documented local Python server on loopback and open its local URL
  in a browser. Diagnose the browser URL, listener port, root page, session
  endpoint, and process working directory before investigating CORE TLS or
  authentication.
- The local preview must use fake clients or read-only target calls during
  development. Never validate Power, Reset, Stop, Jog, or Move by pointing
  test code at a real CORE.

### Safe controls

- Keep Power, Reset, Stop, bounded step-jog, and absolute move server-side.
- Require a fresh per-session safety acknowledgement for non-stop writes.
- Validate finite payloads, discovered capabilities, current axis identity,
  direction-specific velocity limits, and the axis snapshot immediately before
  sending.
- Use the verified Motion command types and HTTP methods. Power uses
  `POST cmd/power` with `{"type":"bool8","value":true|false}`.
- Motion abort rejects JSON `null` with `Data is no object`; use the typed abort
  object with deceleration and deceleration jerk.
- Stop must remain prominent, issue the verified abort command, and confirm a
  stopped PLCopen state within a bounded timeout. Stop does not implicitly
  power off the drive.
- Implement jog as clearly labeled bounded step-jog unless a verified
  press-and-hold contract is available. Release/cancel must issue a stop for
  press-and-hold behavior.
- Write structured audit records without passwords, tokens, cookies,
  authorization headers, or other secrets. Preserve transport and HTTP error
  status; do not turn a 403 or transport failure into a false value.

## Snap Packaging

### Package-assets

For a Unix-socket web snap, keep all of these identical:

- technical snap name and manifest `id`;
- public route, for example `/<snap-name>/`;
- proxy service name, commonly `<snap-name>.web`;
- manifest binding:
  `unix://{$SNAP_DATA}/package-run/<snap-name>/web.sock`;
- launcher socket path:
  `${SNAP_DATA}/package-run/<snap-name>/web.sock`;
- `package-run` slot write path;
- the server's actual Unix socket.

Use the official package-assets schema for the target OS release. Package
manifest variables use `{$VAR}`, not shell-style `${VAR}`.

Do not put MIT, BSD, Apache, or another source-code license in the ctrlX
`licenses` array. That array is for ctrlX device capability identifiers such
as `SWL-...`; `required: true` means a device license is mandatory. Use the
official FOSS information mechanism for third-party notices and declare
`licensing-service` only when the app actually acquires a device license.
Snapcraft's top-level `license` field is package metadata, not an installed
CORE license.

### Runtime

- Declare `daemon: simple` and an explicit restart policy.
- A web server should declare both `network` and `network-bind`; the latter
  grants the server bind/listen capability under strict confinement, including
  the official ctrlX web-server pattern.
- Declare `package-assets` and `package-run` slots as documented.
- Prefer a Unix socket over a TCP port for the reverse proxy.
- For a core24 Python snap, the launcher should use the base runtime's
  interpreter from `PATH`, for example:

  ```sh
  #!/bin/sh
  set -eu
  exec python3 "$SNAP/server.py"
  ```

- Windows-created launchers must be LF-only. CRLF after `#!/bin/sh` causes
  Linux to report `cannot execute: required file not found`.
- Do not assume `$SNAP/usr/bin/python3` exists. In this case core24 supplies
  `python3` through the base runtime, while the earlier absolute `$SNAP` path
  failed.

## Windows-to-ABE Workflow

1. Keep one canonical source tree on Windows.
2. Use the ctrlX WORKS ABE when Windows lacks a usable Snapcraft environment.
3. Verify an SSH login and `snapcraft --version`; an open forwarded TCP port is
   not enough.
4. Copy only source/package files to the ABE. Do not copy credentials, keys,
   VM images, generated build directories, or local logs.
5. Run `source /etc/environment` in the ABE before Snapcraft.
6. Build only the target architecture until it has passed the target test:

   ```bash
   snapcraft pack --destructive-mode --build-for=arm64
   ```

   Keep AMD64 frozen until the ARM64 package is working.
7. Bump the snap version for each target update; do not reuse an old
   same-version artifact.
8. Inspect `snap info`, `unsquashfs -l`, launcher mode/content, package
   manifest, architecture, base, and SHA-256 before installation.
9. Run an ABE smoke test by extracting the snap, starting the packaged
   launcher with temporary `SNAP`, `SNAP_DATA`, and `HMI_SOCKET` values, waiting
   for the socket, and requesting the public route over `curl --unix-socket`.
10. On a real CORE, inspect first and obtain explicit confirmation before
    installing, updating, restarting, or changing device state.
11. For a local snap update, follow
    `recipes/app-update/local-snap-install-update.md`: upload with the package
    manager REST API, poll the installed version, restore OPERATING mode, and
    verify the prefixed portal route plus the event stream.

Each SSH/SCP invocation to the ABE can create a transient
`session-<number>.scope` entry. These are host login sessions, not app
restarts or a build loop; they stop when the connection closes.

## Runtime Diagnosis

The CORE page saying that an app is being initialized is a generic reverse
proxy response. A direct HTTP 502 for the registered app route means:

- package-assets registration and the public route are present;
- the reverse proxy cannot reach a healthy upstream socket.

It does not identify whether the daemon crashed, the socket was never created,
`package-run` is disconnected, or confinement denied the bind. Check these
layers separately:

```bash
snap list <snap-name>
snap services <snap-name>
snap connections <snap-name>
sudo snap logs <snap-name> -n 100
```

If the package runs and serves HTTP 200 over its socket in the ABE but the real
CORE returns 502, target-side service state, interface connections, base/OS
compatibility, and logs are the next evidence. Do not change the manifest or
add plugs blindly.

## Silas Repository Boundary

`vitalisAutomation/kuschke-silas-bachelor-thesis` is a useful secondary
reference for Windows SDK VM automation, ARM64 build scripts, and package
layout. It is not proof that a new app will run:

- its `ctrlx-test-app-for-deployment` example uses `core22`, Flask/TCP, and
  `network-bind`, not the core24 Unix-socket design;
- its README explicitly describes that test snap as not functional;
- its `crosscompiling` snap is a Python console/NumPy example, not a web
  reverse-proxy service.

Use official SDK docs and the target's own service/log evidence as authority.

## Reusable Resolution

For a clean axis HMI:

- keep the UI dependency-free and easy to edit;
- separate Motion, PLC, Data Layer, OS health, and command capabilities;
- normalize only verified values and preserve unavailable/error semantics;
- use opaque server sessions and event-driven subscriptions;
- gate all non-stop writes with safety acknowledgement, limits, revalidation,
  authorization, and audit logging;
- package the web service with a matching package-assets route, `package-run`
  Unix socket, `daemon: simple`, `network`, and `network-bind`;
- validate the launcher in the ABE and inspect the target before installing;
- record architecture, version, source/build environment, and artifact hash.

## Validation Checklist

Before handoff:

- run the existing focused/full tests, Python compilation, and JavaScript
  syntax check;
- verify no credentials, tokens, or secrets enter source, browser storage,
  URLs, logs, or audit entries;
- verify Motion names are real and refresh reflects deletion/addition;
- verify units, zero values, enum labels, current/retained diagnostics, and
  per-axis alarm state;
- verify subscription teardown and powered-standstill updates;
- verify stop payload and command safety checks;
- inspect snap metadata, launcher LF/executable state, manifest, route, socket,
  slots, plugs, and SHA-256;
- smoke-test the packaged launcher and socket in the ABE;
- require explicit confirmation for real-device installation or other
  persistent changes.
