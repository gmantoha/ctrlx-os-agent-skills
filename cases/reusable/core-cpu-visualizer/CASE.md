# Case: Read-only CORE CPU visualizer

## Use When

Use this case when a small read-only dashboard must show total CPU health,
application CPU usage, installed application metadata, and longer-term history
from a ctrlX CORE. It covers both the external Python preview and the installed
core24 web snap.

## Verified Data Sources

Use documented read-only APIs first:

- `GET /task-manager/api/v1/processes?withThreads=false` for live process
  records. Group records by their published `appName`; do not infer an
  application from a process name.
- `GET /package-manager/api/v1/packages` for the installed application
  catalog. A catalog entry proves installation, not that the application is
  running.
- `GET /system/api/v1/cpu` for aggregate and published per-core CPU
  statistics.
- `GET /system/api/v1/sensors` for health sensors, but display temperature
  only when the field and sensor meaning are verified.

The observed CORE exposed only an aggregate CPU entry (`all`) through the
system CPU API. Do not divide, copy, or otherwise transform that value into
per-core or per-application values. If no individual core entry is published,
show `Unavailable` with a diagnostic. An OS-level `/proc/stat` collector would
be a separate, privileged design and was not added.

## Installed-Mode Access

An installed app has two distinct backend access paths:

1. The backend can use local Data Layer IPC through the `datalayer` content
   plug.
2. When the app is opened under the CORE Web UI, the package proxy forwards the
   authenticated `CTRLX-OS-SESSION-ID` cookie to the local backend. The backend
   exchanges that cookie server-side through Identity Manager, keeps the bearer
   token in memory only, and calls the protected Task Manager, Package Manager,
   system CPU, and sensor REST APIs.

The browser must call only the local app endpoints. Never expose, decode, copy,
persist, or log the CORE Web UI cookie or bearer token in browser JavaScript,
storage, URLs, source, or request logs. If the cookie is absent, return an
authentication diagnostic rather than silently falling back to fake or empty
data. Preserve 401 and 403 responses as authentication/authorization
diagnostics; do not turn them into empty data. If both REST and local IPC
sources fail, report both source failures explicitly.

The installed backend should use `https://localhost` as its default CORE host
and allow an explicit environment override only when the target requires a
different local name. Use the documented
`GET /identity-manager/api/v2/auth/token` cookie exchange first; only try the
documented v1 alternatives when the current endpoint returns 404.

The following local nodes were tried during diagnosis but are not established
as standard public contracts on every CORE:

- `framework/metrics/cpu-load/current`
- `framework/metrics/cpu-load/settings`

Their absence must remain an explicit unavailable state. The verified local
aggregate fallback was:

```text
framework/metrics/system/cpu-utilisation-percent
```

That scalar is system CPU only. It must never be converted into guessed
application records. Preserve sanitized Data Layer result names/codes such as
`INVALID_ADDRESS`, `PERMISSION_DENIED`, `TIMEOUT`, and
`CLIENT_NOT_CONNECTED` in diagnostics.

## UI and Polling Decisions

- Keep the source easy to edit: plain HTML, CSS, and JavaScript with local
  copies of frontend libraries.
- Do not load Vue, Chart.js, or other required UI assets from a public CDN.
  Offline means the shell and chart libraries load without Internet; live
  metrics still require LAN/VPN access to the CORE.
- Stamp accepted history samples with the PC clock (`Date.now()`), so the chart
  x-axis reflects the computer's time.
- Keep system refresh choices at 10 seconds, 30 seconds, and 1 minute.
- Refresh application process metrics independently every 2 seconds with no
  user selector.
- Refresh the package catalog about every 60 seconds and health about every
  30 seconds.
- Retain application history for up to four hours and discard older samples.
- Reserve a fixed diagnostic area so changing fallback text cannot move the
  rest of the page.
- Keep installed catalog entries visible when live process data is missing, but
  show their live fields as `Unavailable`.
- A published numeric zero is valid. Missing, malformed, or unavailable fields
  are not zero.

## Failure Interpretation

An installed page that loads but reports
`Local Data Layer read failed for /diagnostics/systems/cpu-load` is not proof
that the snap daemon or Data Layer connection is broken. If the verified
aggregate node works, local IPC is connected and the application-specific node
may simply be unpublished. Test the documented REST endpoints from the
same-origin installed page before adding guessed Data Layer nodes or privileged
interfaces.

The package catalog and application process data are separate sources. A CORE
may publish total CPU while omitting per-application records. Keep the total
card usable, label the source, and leave application rows unavailable rather
than assigning false values. A missing per-core map is also a capability
limitation, not a reason to synthesize values.

## Fast Diagnostic Decision Tree

Check the narrowest layer that can explain the symptom:

| Observation | Meaning and next action |
|---|---|
| The installed route does not load or returns 502 | Check `snap services`, `snap connections`, logs, package-assets registration, and the `package-run` socket before checking data APIs. |
| The route returns 200 but total CPU is unavailable | Check the local IPC connection and the verified aggregate node; do not investigate application names first. |
| Total CPU works but applications/packages are unavailable | Call the same-origin Task Manager and Package Manager APIs. If they are unavailable, keep application data `Unavailable`; do not guess Data Layer nodes. |
| The same-origin API returns 401 or 403 | Treat it as session/authorization failure and show it. Do not downgrade it to an empty response or a false zero. |
| The app-specific Data Layer node is 404/`INVALID_ADDRESS` but the aggregate node works | The CORE is connected but does not publish that application source; use the verified aggregate system value only. |
| `/system/api/v1/cpu` publishes only `all` | Per-core utilization is not available from that source. Do not derive it mathematically. |
| The sensor API is missing or its field meaning is uncertain | Keep temperature `Unavailable` and retain the diagnostic. |
| The ABE socket smoke test is 200 but the real route is 502 | The package contents are not the next suspect; inspect target-side service state, interface connections, base/OS compatibility, and logs. |

## Windows-to-ABE Packaging Loop

For a Windows source tree:

1. Keep one canonical source tree and copy only source/package files to the
   temporary ABE. Never copy credentials, keys, VM images, or local logs.
2. Confirm SSH login and `snapcraft --version`; an open forwarded port alone is
   insufficient.
3. Build one requested architecture at a time, keeping ARM64 active until the
   physical target package works.
4. Bump the snap version for each package update.
5. Inspect metadata, architecture, base, confinement, launcher permissions,
   package-assets route, slots/plugs, staged files, and SHA-256.
6. Extract the snap and run the packaged launcher with temporary `SNAP` and
   `SNAP_DATA` values. Request the Unix-socket route with
   `curl --unix-socket` and require HTTP 200 before deployment.
7. Stop the temporary ABE after validation.

If a reproducible Snapcraft build is blocked by unavailable package-index
networking, do not silently claim a normal build. A previously validated
package can be used only as an explicit emergency repack base: replace the
application files, update `meta/snap.yaml` to a new version, normalize
permissions, rebuild the SquashFS, inspect it again, and record that it was
repacked rather than freshly built. Prefer restoring the ABE dependency path
for future releases.

## Safety Boundary

The visualizer remains read-only. Never validate Power, Reset, Stop, Jog, Move,
installation, update, service restart, or configuration behavior against a
real CORE without explicit confirmation. Real-device inspection, logs, package
metadata, and read-only API calls are separate from persistent deployment.

## Validation Checklist

- Run the existing focused and full tests, Python compilation, and JavaScript
  syntax checks.
- Confirm no credentials, tokens, cookies, or authorization headers enter
  source, browser storage, URLs, logs, or audit records.
- Test aggregate-only CPU responses, missing process data, missing packages,
  missing sensors, 401/403 responses, invalid JSON, transport failures, and
  Data Layer result codes.
- Confirm the system and application polling cadences and four-hour pruning.
- Confirm the chart uses PC-local timestamps and the diagnostic slot is fixed.
- Inspect and socket-smoke-test the package before any target installation.

## Additional Verified Implementation Details

### External authentication compatibility

- Use the target's documented Identity Manager OpenAPI as the authority. The
  preview client was made compatible with targets exposing
  `/identity-manager/api/v2/auth/token`, `/identity-manager/api/v1/auth/token`,
  or `/identity-manager/api/v1.0/auth/token`; treat this as a version
  compatibility fallback, not as permission to guess credentials or suppress
  an authentication error.
- Try an alternate token endpoint only when the current endpoint is
  unsupported. Preserve invalid-credential, authorization, malformed-response,
  and transport failures distinctly.
- In Python preview mode, keep the bearer token in server memory and return
  only an opaque `HttpOnly` session cookie. A browser-only edition can keep a
  token in the current JavaScript closure, but that is a weaker boundary and
  requires CORS and trusted certificate handling.

### Installed Web UI session authentication

- The installed package receives the CORE Web UI's
  `CTRLX-OS-SESSION-ID` cookie on requests routed through the package proxy.
- Exchange that cookie for a bearer token in the backend with Identity Manager;
  do not ask the installed page for a second CORE username/password.
- Attach the bearer token to protected REST requests from the backend and keep
  it process-memory-only. Never return it to the browser or include it in
  diagnostics and logs.
- A missing cookie is an explicit 401 condition. Preserve CORE 401, 403,
  malformed JSON, and transport errors instead of replacing them with local
  zeroes or empty application rows.
- The installed app can still use local IPC for the verified aggregate CPU
  fallback, but that does not replace authenticated Task Manager or Package
  Manager REST data.

### Installed Data Layer client startup

- The verified Python SDK client pattern is `System("")`, `start(False)`,
  then `create_client("ipc://")`. `start(True)` attempts broker startup and
  caused the installed-mode startup failure; a client snap must not start a
  broker.
- The snap needs the `datalayer` content plug mounted at
  `$SNAP_DATA/.datalayer`. Close the client and SDK system during cleanup.
- A successful read of the verified aggregate node proves local IPC is
  connected even when an application-specific node is unpublished. Do not
  diagnose every missing metric as an IPC failure.

### Process and package normalization

- Task Manager records publish `appName`, `name`, `pid`, `cpuUsage` (percent),
  `memoryUsage` (bytes), state, and core information. Request
  `withThreads=false` and aggregate by exact `appName`.
- Sum CPU and memory only from validated, non-negative numeric fields. A
  missing field stays `null`/`Unavailable`; it is not a zero contribution.
- Prefer a package record's published `name`. Use `id` only when that
  alternate identifier is confirmed by the response contract; never derive an
  application name from a title, process name, or array position. Catalog-only
  rows remain visible with unavailable live metrics.

### Fallback and result-code semantics

- Use the documented system CPU endpoint as the external application-node
  fallback only for HTTP 404/not-published responses. Do not replace 401, 403,
  malformed JSON, or transport failures with fallback values.
- The verified local aggregate fallback is
  `framework/metrics/system/cpu-utilisation-percent`; expose it as aggregate
  system CPU only.
- Preserve sanitized Data Layer result names and numeric codes. Observed
  mappings include `INVALID_ADDRESS (0x80010001)`,
  `PERMISSION_DENIED (0x80010014)`, `TIMEOUT (0x8001000F)`,
  `CLIENT_NOT_CONNECTED (0x80030001)`, and
  `SEC_UNAUTHORIZED (0x80070004)`. Do not invent a `NOT_FOUND` SDK constant.
- If total/system data is valid while optional application data is missing,
  show a degraded informational diagnostic rather than a page-level failure.

### Offline and build dependency boundary

- Pin and vendor required browser libraries; the project used Vue 3.5.42 and
  Chart.js 4.4.7 with their license notices. Offline means the shell and
  libraries load without public Internet; live CORE reads still need the
  device network path.
- For Python Data Layer snaps, keep SDK versions explicit and reproduce the
  build environment. The validated project used
  `ctrlx-datalayer==3.5.0`, `ctrlx-fbs==2.5.1`, and
  `flatbuffers==24.3.25`; the ABE also needed the matching SDK Debian package
  and package-index access. A failed dependency-network build must not be
  reported as a normal reproducible build.
