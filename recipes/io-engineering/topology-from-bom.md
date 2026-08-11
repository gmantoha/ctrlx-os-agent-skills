# Building an EtherCAT Topology from a Parts List

General rules for turning a customer BOM / parts list into an IO Engineering project.
Derived from a full 28-slave rebuild, ctrlX IO Engineering 4.6 — 2026-08-11.

Read this **before** `project-and-ethercat-topology.md`, which covers the REST mechanics.

---

## The core rule

> **A BOM tells you *what*, never *where*.**

A parts list is a commercial document. It is not a layout. Two properties destroy
topology information, and neither is recoverable by being clever:

1. **Quantity aggregation.** A row `DO module, Qty 6` cannot tell you the modules sit as
   3 + boost + 3 on the rail. Any contiguous block you assume may be wrong.
2. **Commercial grouping.** Rows are grouped by drive set / order position, which is
   frequently *not* physical bus order.

**Never present a topology derived from a BOM alone as verified.** Say explicitly which
parts were derived and which were assumed.

## What you *can* derive reliably

| From | You get |
|---|---|
| **Cable rows** (`X - Y`) | the real bus chain — this is the authoritative order source |
| Cable count | chain continuity: n devices need n−1 links; a missing link is a BOM defect |
| Connection cables per device | device-to-device mapping (e.g. motor→drive), better than the grouping column |
| "double axis" / multi-channel wording | **slot count, not device count** |
| Licence rows | how many axes/objects may actually be commissioned |

Derive order from **cables**, never from row sequence.

## What you must ask for

If the layout matters, request one of these — in preference order:

1. An existing `.io.project` / fieldbus export (definitive)
2. The tool's `COMPONENT LIST` text export
3. A configurator **Station Details** screenshot (shows real slot order)
4. A rail photo

A BOM plus a system overview screenshot is **not enough** to fix slot order.

## Ordering is not enforced by the tool

Device descriptors declare **no enforceable slot ordering** — `DependOnSlot` /
`DependOnSlotGroup` are generic boilerplate. IO Engineering will **silently accept a wrong
rail order** and produce a valid-looking project.

Consequence: there is no error to catch this. The only tell-tale is the **I/O address
map** — a misplaced module shifts every downstream address. Always generate the address
map as the verifiable artifact and have the customer confirm it against the machine.

## Multi-axis drives are multiple slaves

A double-axis drive is **two independent EtherCAT slaves**, with distinct order numbers
(`1/2`, `2/2`) and separate connectors. Count slaves, not devices:

- 8 double-axis drives = **16** slaves, not 8
- a drive with only one motor populated still occupies **two** slots in the project

Whether an unpopulated axis enumerates on real hardware is **unverified** — flag it, don't
assume.

Drive descriptors exist in both **SoE** and **CoE** variants with different ids and
revisions. Ask the customer which protocol; do not pick silently.

## Couplers may be absent — and may not be needed

Do not assume a bus coupler. Many BOMs contain none.

**IO modules can be inserted directly under `ethercatmaster`** without a coupler (verified
by test insert, 4.6). If the BOM has no coupler, do not invent one — ask. Inserting a
phantom coupler shifts addresses and silently corrupts the whole map.

## Resolving material numbers

Match material numbers against the local device cache rather than guessing from
descriptions:

```
C:\ProgramData\Rexroth\IOE-V-{version}\0\Studio\Devices\{deviceType}\{id}\{encodedVersion}\
```

```powershell
# installed devices come back under .installedDevices (NOT .devices)
(Invoke-RestMethod "$base/device-repositories/System Repository").installedDevices
```

**Guessing material numbers from a bare-number BOM produces confident, wrong answers.**
Controllers and licence dongles are especially easy to mistake for infrastructure parts.
If a number cannot be matched in the cache, report it as unresolved.

Where multiple cached revisions exist for one module, the BOM usually carries no revision
data — state which revision you chose.

## Terminology differs between tools

The same physical part has different names in different Rexroth tools (e.g. a power-feed
module appears as *"Power feeder UP"* in IO Engineering and *"Boost module"* in the I/O
configurator). When a customer's document and the tool disagree on a name, match on
**material number**, not on the label.

## Validate the result

`ExportEthercatConfigJob` doubles as a **validator** — it fails on a broken topology.
Requires **both** `filePath` (folder) and `fileName`, otherwise:
`Information 'fileName' missing.`

Check the returned `<Slave>` count and `Info.PhysAddr` range against your expected slave
count.

## Recommended sequence

1. Parse the BOM: devices, quantities, cables, licences
2. Build the chain from the **cable rows**; flag any missing link
3. Convert multi-axis devices to slave counts
4. Resolve every material number against the device cache; list unresolved ones
5. **Ask** for a layout source before fixing slot order
6. Build, save, run `ExportEthercatConfigJob`, compare slave count
7. Produce the **I/O address map** and hand it over as the artifact to confirm
8. State clearly what was derived, what was assumed, and what is unverified
