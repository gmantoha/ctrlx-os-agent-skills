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
