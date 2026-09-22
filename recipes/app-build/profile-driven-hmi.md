# Profile-Driven PLC HMI

Use this recipe when a read-only ctrlX web HMI must work across PLC projects
whose published Data Layer symbols are not identical.

## Start with one decision

Before implementing an HMI, ask:

> Should we start from the basic HMI template as a clean baseline, or adapt an
> existing PLC project?

The basic template can provide a useful starter structure and known examples,
but it is not a universal PLC contract. If the user chooses an existing
project, request its PLC version, symbol export or browse result, desired
read/write behavior, and any existing HMI conventions.

## Architecture

Keep these capabilities separate:

- **PLC profile**: the symbols actually published by the selected PLC project.
- **Motion**: the independent Motion service/tree. Motion may be available even
  when no supported PLC profile exists.
- **UI capabilities**: pages and polling enabled by discovered capabilities, not
  by a fixed list of assumed paths.

Every project needs an explicit mapping from logical HMI fields to its symbols.
Use the template mapping only when the user selected that template and the
target symbols have been verified. Do not infer customer-specific write
controls from names or types alone.

## Discovery rules

1. Establish the correct Data Layer root from official project/device
   documentation or a read-only browse; never guess a variable path.
2. Browse with explicit depth, item/byte, and time limits.
3. Identify contract markers and build a profile containing the observed paths,
   capabilities, and diagnostics.
4. Distinguish a successful browse with no recognized contract from transport,
   authentication, timeout, and malformed-response failures.
5. Treat an unrecognized project as a valid `unknown` profile, not as a broken
   PLC, while keeping independent capabilities available.
6. Avoid long-lived caching unless PLC-switch invalidation is explicit.
7. Do not use broad catches or turn failed reads into false values.

## Read-only normalization

Create project-specific adapters for status, mode, version, heartbeats,
alarms, warnings, CORE state, EtherCAT state, or other overview data. Validate
the type and shape of every read before normalization. A missing field,
unsupported alias, wrong type, or failed read must remain an explicit
unavailable diagnostic.

Do not add write controls for unknown/customer variables. If a control is
required, obtain its documented path, type, permissions, and safety behavior
from the project owner before implementing it.

## UI gating

- Show a page only when its profile capability is available.
- For an unsupported or unknown PLC profile, show a clear explanation instead
  of repeatedly polling missing paths.
- Show Operate axes only when Motion discovery succeeds.
- Preserve authentication/session behavior and avoid polling unavailable pages.

## Tests

Use fakes and project fixtures. Cover:

- template-baseline and existing-project flows;
- recognized, unknown, and failed discovery;
- bounded browse and read failures;
- missing and wrong-type field diagnostics;
- Motion available independently;
- capability-aware navigation and polling;
- regression behavior for each supported project adapter.

## Field lessons from a cross-project Smart HMI

### Treat the profile as a published contract, not a project name

The profile name is a classification of the symbols currently published by the
PLC. It is not the PLC project name and must not be presented as one. Display
PLC-reported metadata such as `strPlcPrgVersion` separately when it is
available.

One verified pair of contracts is:

- Legacy PLC axis details:
  `/plc/app/Application/sym/GVL_HMI/Axis_HMI`
- PLC-HMI template:
  `GVL_BASE` plus `GVL_CORE` and/or `GVL_EtherCAT`

The template's alarm arrays were published as `GVL_BASE/arAppAlarm`,
`GVL_BASE/arAppInfo`, and `GVL_BASE/arAppWarn`, not necessarily as
`alarms`, `info`, and `warnings`. Map both spellings to stable logical keys,
but keep missing fields and wrong types as diagnostics.

Do not infer a contract from a screenshot, PLC application name, or one
successful read. Browse the symbol root, retain the observed paths, and expose
the distinction between:

- a valid recognized profile with optional data missing;
- a successful browse with no recognized specialized contract (`unknown`);
- a transport, authentication, timeout, malformed-response, or bounded-limit
  failure.

### Keep Motion independent from PLC symbols

`/motion/axs` is a separate service tree. A Motion axis is not automatically a
PLC `Axis_HMI` record, even when both describe the same physical axis. The
Operate page should use names discovered from Motion and should read the
selected axis through a name-safe per-axis route. Legacy numeric PLC selectors
must not be used as a fallback for Motion.

This avoids the common phantom `Axis 1` failure mode: a default
`selectedIndex = 1`, a server-selected index that was not validated against
the browse result, and trace polling against `/api/state?index=1` can display
an axis that does not exist. Use `null`/unavailable until a real published
record is discovered. Refresh the Motion list when Operate or Signal traces
opens, and do not manufacture an option when discovery is empty.

For Motion operation and traces:

- keep Operate axes and Signal traces as the two clear Motion views;
- show the current selected-axis state in Operate;
- display the selected axis's published position, velocity, acceleration, and
  jerk units beside inputs;
- allow signed velocity only after checking the direction-specific
  `velocityNegative`/`velocityPositive` limits;
- send the validated velocity magnitude in the typed Motion `lim.vel` payload;
- preserve legacy trace fallback only when actual legacy PLC records exist;
- make a first collected chart sample visible, since one canvas point has no
  line segment.

### Do not turn PLC-specific status names into generic machine health

Names such as `GVL_CORE/ctrlX_CORE_Status` and
`GVL_EtherCAT/GLB_EtherCAT_Status_1` may be application symbols from one PLC
program. They are not universal ctrlX OS health contracts. Do not make them
the generic Machine health source or require them for a valid template profile.

Use the read-only ctrlX OS system APIs such as
`/system/api/v1/cpu` and `/system/api/v1/sensors` when true CPU or temperature
metrics are required, and match sensors conservatively by published metadata.
Hardware and virtual targets may expose different sensors. If a metric cannot
be verified, show `Unavailable` with its diagnostic. For project-specific
symbols, keep the bounded Data Layer Explorer as the generic inspection path.
It is acceptable to retain compatibility readers internally while removing
their dedicated visible cards, navigation, and polling from the generic HMI.
Machine health should be read on demand when the page opens or when the user
refreshes it; it should not create a second background polling loop.

The Explorer is a useful general escape hatch: start at the conventional
`/plc/app/Application/sym`, browse one bounded level at a time, present the
common path as `sym -> GVL -> child`, and keep the raw authorized path field
available. Node inspection should infer type/presentation kind and cap
structure/array previews. Pinned values should remain read-only and
session-only until a separately designed, versioned mapping system exists.

### Diagnose browser `Failed to fetch` from the outside in

A browser fetch error during local sign-in is often a dead or mismatched local
HMI process, not bad credentials or a CORE certificate problem. Check, in
order:

1. the browser URL and the listener port are identical;
2. `GET /` returns the expected HTML;
3. `GET /api/auth/session` returns HTTP 200 before login;
4. the HMI process command line/cwd points at the canonical source;
5. only then inspect CORE authentication and Data Layer responses.

A local launcher may default to one port while the browser is open on another
(for example, 8099 versus 8100). Python also keeps old backend code in memory,
so a changed static frontend can be paired with an old backend until the local
preview is restarted. For a virtual CORE with a self-signed certificate,
`CTRLX_TLS_VERIFY=false` is a local development setting only; never change
device certificate settings to fix this symptom.

### Keep the canonical source and runtime copies explicit

When a project exists both in a folder-backed session and in a normal source
repository, identify the canonical copy with `git remote -v`, the running
process cwd, the active preview port, and the test results. Do not edit one
copy while serving another. Preserve stable and newer HMI variants in separate
directories and package identities; do not copy one over the other.

## Safety and validation

Keep CORE Identity Manager authentication authoritative. Store the CORE token
only in the server-side session, return CORE authorization denials as
HTTP 403, and do not add role inference or duplicate permissions in the HMI.
Non-stop Motion writes need an explicit safety acknowledgement, typed payload
validation, re-browse/limit checks, and structured audit logging without
credentials or raw secrets.

Use fake Data Layer clients for profile, overview, Motion, and failure tests.
At minimum, validate recognized/unknown/failed discovery, bounded browsing,
template aliases, missing/type diagnostics, independent Motion capability,
capability-gated polling, no synthetic axis, and legacy regressions. Run
Python compilation, JavaScript syntax checks, focused tests, and the full
existing suite before rebuilding a snap.
