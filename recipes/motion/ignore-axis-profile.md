# DRIVEAXS Without Physical Drive — ignore-axisprofile

Verified on ctrlX OS 4.6, **virtual** ctrlX CORE lab — 2026-07-31.

## Context

`axis-create-delete.md` and `switch-to-running-mode.md` reference an
`ignore-axisprofile=true` setting that is supposedly required before a
`DRIVEAXS` axis created **without a physical drive** can survive the
Configuration → Running (`scheduler/admin/state` → `OPERATING`) switch
without a reboot. This file was referenced from `SKILL.md` but did not
exist yet — this is the missing writeup.

## What Was Actually Tried

Node discovery on a freshly created DRIVEAXS axis (`CopilotAxis`, no
physical drive attached):

```
GET /automation/api/v2/nodes/motion/axs/CopilotAxis/cfg?type=browse
→ ["axisprofile","common-properties","dev-err-reaction","functions",
   "kin-properties","lim","load","properties","realtime",
   "realtime-inputs","save","units","unsaved"]

GET /automation/api/v2/nodes/motion/axs/CopilotAxis/cfg/axisprofile
→ {"type":"string","value":""}   -- exists, empty string, no children
```

Attempting to set it as a boolean flag **fails**:

```
PUT /automation/api/v2/nodes/motion/axs/CopilotAxis/cfg/axisprofile
Body: {"type":"bool8","value":true}

→ 400 Invalid parameter
  dynamicDescription: "Invalid data type: String expected ,DLResult: DL_TYPE_MISMATCH"
```

So `cfg/axisprofile` is a **string** node (likely meant to reference a
named drive/axis profile, not a boolean ignore-flag). `ignore-axisprofile`
is not this node — its real location is still unconfirmed.

## What Actually Worked (No Special Setting Needed)

On this virtual lab, switching straight from Configuration back to
Running worked without touching `axisprofile` at all:

```
PUT /automation/api/v2/nodes/scheduler/admin/state
Body: {"type":"object","value":{"state":"OPERATING"}}
→ 200, motion/state/opstate becomes "Running" within ~10s
→ motion/axs/CopilotAxis/state/opstate/plcopen = "DISABLED" (correct idle state)
```

No `0xf0100001` deadlock, no reboot required.

## Open Question / Next Steps

- The original `ignoreAxisProfile=true` deadlock described in `SKILL.md`
  may be specific to **real hardware** with an EtherCAT master expecting
  a drive that never answers — not reproducible on the virtual lab where
  no fieldbus scan blocks the transition.
- If the deadlock is hit again on real hardware, capture the exact node
  path used (Web UI network tab / Data Layer Diff via
  `workflows/learn-from-ui.md`) before assuming `cfg/axisprofile` is the
  right target.

## Takeaway

- Do not `PUT` a bool to `motion/axs/{name}/cfg/axisprofile` — it expects
  a string and will fail with `DL_TYPE_MISMATCH`.
- On a virtual ctrlX CORE, a DRIVEAXS axis without a physical drive can
  switch Configuration → Running directly with no extra step.
- Treat the "no reboot needed" claim in `switch-to-running-mode.md` as
  **confirmed for the virtual lab**; real-device behavior still needs
  verification.
