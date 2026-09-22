# Offline-first ctrlX PLC/HMI project workflow

Use this recipe when creating a new ctrlX PLC project together with a local
web HMI, especially when development should continue without a connected CORE,
when the live HMI should be subscription-driven, or when PLC, Motion, and
EtherCAT data must remain separate capabilities.

This is a development and architecture workflow. It does not replace the
device-specific recipes for Motion, IO Engineering, app installation, or
persistent device configuration.

## Core principles

1. **Develop offline first, verify on a target second.** Source code, PLC
   contracts, HMI layout, fake Data Layer clients, and most tests do not need a
   CORE. Authentication, exact published node paths, live subscriptions,
   EtherCAT state, Motion state, and deployment do.
2. **The PLC owns process truth.** The HMI renders the latest PLC snapshot and
   sends only allow-listed, typed commands. It must not calculate a competing
   process state or silently simulate successful writes.
3. **Discover capabilities before using them.** Browse the actual PLC, Motion,
   IO, and OS trees; do not infer paths from a project name, screenshot,
   numeric axis index, or a generic example.
4. **Keep capabilities independent.** A PLC profile, Motion axes, EtherCAT
   diagnostics, OS health, and HMI presentation are separate layers. One
   unavailable capability must not make the others appear broken.
5. **Use evidence in layers.** Prefer official documentation and verified
   project/device browse results, then local fakes and tests, then a virtual
   CORE, and finally a real device with explicit confirmation before
   persistent changes.

## What can be done offline

| Work item | Offline without a CORE | Requires target verification |
|---|---:|---:|
| Define DUTs, GVLs, POUs, state machines, limits, and command contracts | Yes | PLC runtime behavior |
| Create and build a PLC project in local PLC Engineering | Yes | Download, login, and start |
| Design HTML/CSS/JavaScript and a responsive HMI layout | Yes | Browser behavior behind the CORE proxy |
| Implement a fake Data Layer snapshot/event client | Yes | Actual node types and permissions |
| Test subscription merging, diagnostics, acknowledgements, and failures | Yes | Event timing and disconnect behavior |
| Build a snap when the required toolchain/dependencies are present | Usually | Target architecture and runtime |
| Browse live PLC symbols, Motion axes, or EtherCAT topology | No | Yes |
| Validate CORE authentication, TLS, permissions, and portal cookies | No | Yes |
| Validate Motion commands, virtual-axis state, or fieldbus state | No | Yes |

“Offline” does not mean that target-specific facts may be guessed. Mark
unverified paths, types, units, and capabilities as unknown until they have
been browsed on the target.

## 1. Classify the target and the change

Before editing or connecting, record:

- `offline`: no device calls; local source, fakes, tests, and design only;
- `virtual`: local or hosted virtual ctrlX CORE;
- `real`: physical ctrlX CORE or machine.

For a device task, check whether the `ctrlx-ai` snap/MCP server is available
before choosing REST, SSH, WebDAV, or Web UI. Read the matching workflow and
`reference/AGENTS.md` first.

Inspection and drafting are safe without confirmation. On a real device,
obtain explicit confirmation before installing/updating/removing apps,
transferring PLC or IO configuration, changing Motion state, restarting
services, rebooting, or writing network, firewall, user, certificate, storage,
or other persistent configuration.

For a virtual lab, check and report its status before and after the work, and
stop it when testing is complete unless the user explicitly wants it left
running.

## 2. Choose the architecture before writing UI code

Decide whether the project is:

- a clean baseline PLC/HMI template;
- an adapter for an existing PLC contract;
- a simulation-only demo;
- a real Motion/IO application; or
- a combined project with independent PLC, Motion, and IO diagnostics.

Use an explicit operating mode when simulation and real Motion may coexist:

```text
SIMULATION   PLC calculates the process snapshot
MOTION       Motion axes provide actual joint state; PLC coordinates the task
IO_DIAGNOSTICS  HMI displays EtherCAT/IO state read-only
```

Keep one normalized HMI snapshot shape, but preserve the source and
availability of each field. Do not present a simulated position as an actual
encoder value.

For an existing PLC, first request or obtain its PLC version, symbol export or
bounded browse result, expected read/write behavior, and existing HMI
conventions. A PLC application name is not a published contract.

## 3. Define the PLC contract first

Create the contract before designing controls:

- version/capability marker;
- limits and units;
- home pose and target pose;
- current pose and orientation;
- process/state enum;
- command structure;
- monotonically identifiable command ID;
- acknowledgement/reject/timeout fields;
- heartbeat or freshness information;
- diagnostic code and message;
- explicit read-only versus writable symbols.

A maintainable Structured Text layout is:

```text
DUT_*             shared types and enums
GVL_*Contract     limits, constants, demo points, version
GVL_*IO           published PLC/HMI symbols
FB_*              validation, state machine, interpolation, diagnostics
PLC_PRG           one cyclic entry point
```

The PLC should:

1. validate finite values and limits;
2. reject invalid or stale commands explicitly;
3. own interpolation and process state;
4. publish a coherent snapshot;
5. acknowledge the exact command ID;
6. never report success only because a browser request was received.

For a demo, a Cartesian six-axis pose can be simulated. It is not a
replacement for forward kinematics. When actual Motion axes are introduced,
read joint values, apply verified robot geometry, and derive TCP pose in the
PLC or a dedicated motion adapter.

## 4. Create and deploy the PLC in controlled steps

For local PLC Engineering automation, use the Engineering REST API rather than
assuming `CODESYSScript.exe` exists:

```text
http://localhost:9002/plc/engineering/api/v2
```

Recommended order:

1. Open the project and verify `GET /projects/current`.
2. Create or update POUs and GVLs.
3. Use `elementType = "GVL"` for a GVL; do not create it as a POU.
4. Save the project.
5. Build with `BuildJob` and `action = "GenerateCode"`.
6. Verify zero build errors.
7. Configure and verify symbol selection/access rights.
8. Log in to the device.
9. Download with `ApplicationLoginJob` and `LoginWithDownload`.
10. Start with `ApplicationJob` and `action = "Start"`.
11. Browse the published symbols and read a known value.

Serialize Engineering jobs. Wait for each job to finish before submitting the
next; parallel jobs produce `blocking operation in progress`.

Keep the tested URL conventions:

| Operation | `nodeUrl` form |
|---|---|
| Communication settings | `/devices/Device` |
| Device login | `/devices/Device` |
| Application login | `devices/Device/Plc Logic/Application` |
| Application start | `devices/Device/Plc Logic/Application` |

The local PLC Gateway and CORE HTTPS ports must be confirmed for the current
target. Do not copy port numbers from a different lab or release without
checking.

## 5. Design the HMI as an adapter, not a second controller

Recommended runtime:

```text
CORE Data Layer / REST
          ↓
server-side HMI adapter
          ↓
browser session and visual components
```

Keep the CORE host, credentials, bearer token, and authorization headers on
the server. Return only an opaque session cookie to the browser. Never put
secrets in HTML, JavaScript, URLs, local storage, audit logs, or snap
metadata.

For a small dependency-free HMI, plain HTML/CSS/JavaScript and a Python
standard-library backend are sufficient. Use a component framework only when
the project has a real dependency requirement.

### HMI design rules learned from the arm project

- Make the process data the visual focus; decorative elements must not imply
  a sensor, target, or physical object that does not exist.
- Keep a single coordinate system and a single source of truth for position.
- Separate the process visualization from diagnostics and engineering details.
- Use a clear hierarchy: current state, current values, target/command, then
  diagnostics and advanced details.
- Show `Unavailable`, `Unknown`, or a diagnostic reason instead of rendering
  missing data as zero or as a successful state.
- Use responsive layout and preserve readable values when the viewport or
  visualization is zoomed.
- For a 2D/SVG perspective view, label it as a visualization; do not imply
  CAD accuracy or actual joint kinematics.
- Keep axes, points, arm geometry, and coordinate labels in the same projected
  world space. Do not leave a base or overlay statically anchored while the
  scene zooms.
- Do not add controls for unknown/customer symbols. Controls require a
  verified path, type, permission, limit, and safety behavior.
- Keep Stop prominent and do not hide safety-critical status in a decorative
  panel.

Gate pages and polling from discovered capabilities. For example, show an
Operate page only after Motion axis discovery succeeds, and show an IO page
only after the relevant fieldbus tree is available.

## 6. Implement live values with subscriptions

Use a snapshot-plus-events pattern:

1. Browse and read an initial snapshot.
2. Discover the selected axis, PLC profile, or IO instance.
3. Subscribe to the documented Data Layer events endpoint, for example:

   ```text
   /automation/api/v2/events?nodes=...&publishIntervalMs=...
   ```

4. Merge node-bearing events into the displayed model.
5. If an event has no usable node or the stream reports a gap, perform an
   explicit bounded snapshot refresh.
6. Close subscriptions on axis change, logout, browser disconnect, and
   session expiry.

For Motion:

- keep a small state/power sentinel subscription;
- arm value subscriptions when powered state is verified, including powered
  standstill;
- keep value subscriptions through standstill and movement;
- release them after confirmed unpowered state or disconnect;
- never invent a numeric axis or convert a Motion name to a PLC array index.

Do not subscribe to command nodes as normal telemetry. Commands remain
server-side, typed, allow-listed, acknowledged, and separately audited.

Bound queues and define backpressure behavior. Do not replace a verified
event stream with an unbounded browser timer. Use on-demand reads for
machine-health cards or slow diagnostics rather than creating duplicate
background polling loops.

### Offline subscription testing

Create a fake client that can emit:

- an initial snapshot;
- node-bearing events;
- out-of-order events;
- an event without a node;
- disconnects and timeouts;
- invalid types and explicit zero values;
- axis deletion or capability disappearance.

Test the reducer/normalizer without a CORE. Then verify the actual event path,
payload types, publish interval, permissions, and disconnect behavior on a
virtual or real target.

## 7. Develop and preview locally

Keep one canonical source tree. Before diagnosing behavior, record:

- repository or source path;
- running process working directory;
- browser URL and listener port;
- active frontend/backend revision;
- test result and, for snaps, artifact hash.

Do not edit one copy while serving another. Restart the local backend after
backend changes; Python can keep old code in memory while a changed frontend
is loaded.

For a fully offline preview:

- use fake Data Layer/REST clients;
- use synthetic PLC snapshots and event streams;
- keep the server on loopback;
- do not require credentials;
- test command validation without sending commands to a CORE;
- use fixtures for recognized, unknown, and failed PLC profiles.

Diagnose a browser `Failed to fetch` from outside in:

1. compare the browser URL with the actual listener port;
2. request `/` and confirm the expected HTML;
3. request `/api/auth/session`;
4. verify the process command line and working directory;
5. only then inspect CORE authentication, TLS, or Data Layer responses.

`CTRLX_TLS_VERIFY=false` is acceptable only for a local development target
with a self-signed certificate. Do not change device certificate settings to
fix a local preview problem.

Offline development cannot prove CORE authentication, exact node paths,
subscription permissions, EtherCAT state, or runtime scheduling. Record those
as target-verification items.

## 8. Keep IO and Motion visible without coupling them to the demo

IO Engineering is a separate configuration layer. It describes the
EtherCAT master, slaves, modules, PDOs, addresses, and mapping. Motion is a
separate service tree and may expose virtual axes even when no physical
EtherCAT drive is present.

For a read-only HMI diagnostics page:

- browse the actual fieldbus master tree;
- browse `/motion/axs` independently;
- display discovered names, states, actual values, units, and diagnostics;
- keep a missing tree as an unavailable capability;
- do not assume that an IO project file is readable by a deployed HMI;
- prefer live CORE state for runtime status;
- use an exported topology only as a clearly labelled static configuration
  snapshot.

Do not change the existing simulated PLC movement merely to show IO data.
Add a separate `IO & Motion` view and introduce real axis control only after
the topology, axis mapping, limits, and Motion operating mode are verified.

## 9. Validate in layers

Before target deployment, run the smallest checks covering the change:

- PLC source/contract tests;
- Python compilation and focused server tests;
- JavaScript syntax checks;
- HMI browser smoke test;
- fake Data Layer subscription tests;
- capability discovery and unknown-profile tests;
- acknowledgement, timeout, reject, and stale-ack tests;
- package inspection before installation.

For a snap:

1. build the requested architecture only;
2. inspect architecture, base, confinement, manifest, launcher, route, and
   socket contents;
3. run a packaged smoke test in the ABE;
4. install on a real CORE only after inspection and confirmation;
5. verify service state, logs, package-assets route, socket, and live HMI
   stream;
6. keep the ABE and target state distinct.

For a virtual CORE, report status before and after and stop it after testing
unless explicitly requested otherwise.

## 10. Common failures and correct interpretation

| Symptom | First interpretation |
|---|---|
| Browser `Failed to fetch` | Check local port, root route, session endpoint, and process cwd before credentials |
| Generic “app is initializing” page | Reverse proxy route exists; inspect daemon/socket/package-run health |
| HTTP 502 on app route | Upstream socket or daemon is unhealthy; not automatically a manifest error |
| `blocking operation in progress` | An Engineering job is still running; serialize and poll jobs |
| Empty PLC symbol browse | Check download, symbol selection, connection, and permissions |
| Phantom `Axis 1` | A numeric/default selector was invented instead of using discovered Motion names |
| `[object Object]` in UI | A typed IEC enum/object was rendered without decoding |
| Error on every axis | A per-axis diagnostic was incorrectly promoted to global health |
| Stale command accepted | Ack was not matched to the current command ID |
| Visual arm differs from PLC path | HMI calculated a second trajectory or used inconsistent coordinates |
| IO project visible in Engineering but not HMI | Engineering configuration is local/static; browse the live CORE tree separately |

## Handoff checklist

Before saying that a PLC/HMI project is complete, record:

- canonical source path and revision;
- offline checks that passed;
- target-only checks still outstanding;
- PLC contract and published symbols;
- HMI capabilities and unavailable diagnostics;
- subscription lifecycle and fallback behavior;
- authentication and secret handling;
- Motion/IO topology and what was not assumed;
- package/version/architecture if a snap was built;
- virtual or real target status before and after;
- every persistent device change and its confirmation.
