# Case: Data Layer axis HMI with PLC status and subscriptions

## Use When

Use this case when a read-only ctrlX web HMI must show Motion axes together
with PLC-published axis status, live values, diagnostics, and engineering
units without inventing PLC mappings or using a permanent browser polling loop.

## Problem

Motion axis discovery and PLC symbol publication are separate contracts. A
PLC application may publish an axis status array whose records are not aligned
with Motion axis indices or names. A HMI that assumes an array index, treats a
configuration flag as drive power, or merges retained diagnostics with current
alarms will show phantom axes, stale values, or false errors.

## Verified Findings

### Discovery and PLC mapping

- Discover axes by browsing the independent Data Layer tree
  `/motion/axs`. Use only the returned, name-safe axis names.
- Discover the PLC symbol root separately. For the common AxisInterface
  template, verify the published `Axis_HMI` structure and its `Admin`, `Data`,
  `Diag`, and `Units` fields; do not assume that the path or template exists.
- Match a PLC record to a Motion axis only through a published identity field
  such as `Admin.Name`. Never infer an array index from a Motion name.
- An empty identity field, invalid `DataValid`, a missing leaf, or a failed
  read is an explicit unavailable condition. Do not replace it with a guessed
  axis, false flag, or zero.
- Refresh and selected-axis requests should re-browse the current Motion tree.
  This removes deleted axes and discovers newly published names when a target
  changes.

### Data Layer values and diagnostics

- ctrlX IEC enum values can arrive as one-member objects, for example
  `{"CXA_CommonTypes.ERROR_CODE":"RESOURCE_ERROR"}`. Decode the member label
  before rendering; direct JavaScript string conversion produces
  `[object Object]`.
- Preserve published numeric zero. Only missing, invalid, or unreadable values
  should be rendered as `Unavailable`.
- Motion diagnostics and PLC AxisInterface diagnostics are separate per-axis
  sources. Keep their source, severity, code, table, numbers, and message
  distinct.
- A retained PLC diagnostic record can remain nonzero after the current Motion
  and PLC status becomes healthy. A retained code or message alone is not an
  active alarm.
- Determine current alarm state from current status signals such as Motion
  error level or `ERRORSTOP`, and PLC `HasError` or `ErrorStop`, rather than
  from historical diagnostic payloads alone.
- Diagnostics belong to the selected axis. One axis having a PLC or Motion
  error does not make every axis faulty.

### Power-aware subscriptions

- A configuration or activation flag such as Motion `state/activated` is not
  sufficient evidence of actual drive power. Prefer verified PLC `PowerOn` or
  an equivalent published power signal together with PLCopen state.
- In the observed Motion contract, `DISABLED` represented unpowered,
  `STANDSTILL` represented powered and ready, and discrete/continuous motion
  represented active movement. Verify these semantics for the target version.
- Keep a minimal state/power sentinel subscription while an axis is connected.
  When power-on is detected, arm the discovered value subscription immediately,
  including powered standstill; do not wait for movement.
- Keep the value subscription active through powered standstill and movement.
  Release it only after confirmed unpowered state or connection close. If a
  quiet-period optimization is used, the sentinel must be able to re-arm the
  value subscription and the last confirmed values must be retained.
- The REST Data Layer events endpoint emits initial values and subsequent
  changes. A node-bearing event can be merged directly into the displayed
  model. An event without a usable node requires an explicit snapshot refresh.
- Exclude command nodes from normal read-only value subscriptions. Keep
  subscription queues bounded and close them on axis changes, logout, browser
  disconnect, and authentication expiry.

### Safe command boundary

- A Motion abort command that receives JSON `null` can fail with `Data is no
  object`; use the verified typed abort object containing deceleration and
  deceleration jerk.
- Keep command capability discovery, fresh axis revalidation, finite payload
  validation, direction-specific limits, per-session acknowledgement, and
  audit logging server-side. The browser must not receive CORE bearer tokens.
- Stop confirmation is bounded and should check a stopped PLCopen state. Stop
  does not implicitly power the drive off unless that is a separate,
  explicitly requested operation.

### Windows-to-ABE packaging

- A Windows host without Snapcraft, Docker, or a usable WSL distribution is
  not evidence that snap packaging is impossible. Use the ctrlX WORKS ABE.
- A TCP-open forwarded ABE port is insufficient. Confirm an SSH banner/login
  and run `snapcraft --version` before synchronizing a build.
- Keep canonical Windows source, Linux ABE build tree, and Windows artifact
  storage separate. Inspect the snap before deployment and record source
  revision, target architecture, base, metadata, and SHA-256.
- For a web snap, the package-assets proxy mapping, launcher, Unix socket,
  and `package-run` slot must use the same route and path. Proxy service names
  use the `<snap-name>.web` form, manifest variables use `{$SNAP_DATA}`, and
  the app must create and remove its own socket.

## Reusable Resolution

Implement the HMI as separate, capability-aware layers:

1. Browse Motion names independently from PLC symbols.
2. Map PLC records only through published identity and validity fields.
3. Normalize verified values, types, units, and current/retained diagnostics
   without silent defaults.
4. Use a state/power sentinel plus a power-aware Data Layer SSE subscription.
5. Keep browser sessions opaque and command writes server-side, typed, gated,
   revalidated, and audited.
6. Validate with fake clients and contract tests before using a virtual or
   real target.

## Validation Checklist

Before handoff, confirm:

- no synthetic or numeric fallback axes appear;
- deleted and newly published axes are reflected after refresh;
- published zero values and units render correctly;
- enum objects render as labels rather than `[object Object]`;
- current and retained diagnostics are visibly separated per axis;
- value subscriptions arm at powered standstill and release only when
  unpowered or disconnected;
- no browser timer polling loop is required;
- 403 and transport errors retain distinct semantics;
- package route, manifest, launcher, socket, and `package-run` paths agree;
- the snap is inspected before any installation, with real-device confirmation
  still required for installation or other persistent changes.
