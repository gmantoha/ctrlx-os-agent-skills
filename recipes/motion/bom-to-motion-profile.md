# Build a Motion Profile from a Drive BOM / Parts List

Verified 2026-08-11, ctrlX OS 4.6 virtual — 15 axes created in one pass, booted clean,
powered and moved.

Use when a customer sends an Excel/CSV parts list (motors, drives, cables, licences) and
you need the matching Motion axis configuration.

## 1. Read the BOM structure first — do not start at the motor rows

A Rexroth drive BOM export typically has: `System`, `Drive Set`, `Name`, `Description`,
`Material Number`, `Type Code`. Extract in this order:

1. **Converter vs. inverter.** `XCD2…` = converter (mains supply, usually with a
   `XNF1…` mains filter). `XMD2…` = inverter (fed from the DC bus). There is normally
   exactly one converter per system, and it is physically first in the line.
2. **Axis slots.** "Inverter, double axis" / "Converter, double axis" = **2 axis slots
   per device**. Count slots, not devices.
3. **Motor-to-drive mapping.** Read it from the hybrid-cable rows
   (`Motor 09 - Drive 05`), not from the Drive Set grouping.
4. **Physical order.** Read it from the network-cable chain
   (`Drive 01 - Drive 02`, `Drive 02 - Drive 03`, …). This is the EtherCAT order and the
   order axes should be numbered in.
5. **Licences.** `SWL-…-MOT-…` rows cap how many axes you may commission.

## 2. Cross-checks that catch real BOM errors

Run all of these — each has caught a genuine defect:

| Check | Expected |
|---|---|
| hybrid cables | exactly 1 per motor |
| network cables | (number of drives − 1) for a daisy chain |
| **control → first drive cable** | **must exist** — frequently missing, since the chain rows only cover drive-to-drive |
| axis slots vs. motors | slots ≥ motors; report unused slots |
| **licensed axes vs. motors** | licences ≥ motors; if equal, report that spare slots cannot be commissioned |
| DC-bus links converter → inverters | present, or confirmed as integrated busbar |
| Drive Set numbering vs. chain order | often *not* the same; state the mapping explicitly |

The licence check matters most. `…-MOT-STDMOTION**10-…` plus an axis-package row can add
up to exactly the motor count, meaning a physically free second slot on the last drive
**cannot be used without buying another licence**. Confirm against the licence
certificate — type codes in these exports are often partly masked.

## 3. What the BOM does not tell you — ask, do not guess

- **Axis type.** A parts list with motors but no gearboxes/spindles/mechanics does not
  determine LINEAR vs. ROTATIONAL. Default to `ROTATIONAL` (motor shaft, degrees) and say
  so; mechanics change it to `LINEAR` plus a scaling factor.
- **Encoder / absolute vs. incremental.** Decides whether homing is needed. Do not infer
  it from the motor type code — use the configurator.
- **Limits.** `velPos`, `acc`, `trqPos` come from the motor datasheet. Placeholder values
  must be labelled as placeholders.

## 4. Create the axes

Motion must be in **Configuration** (see `motion-opstate-switch.md`). Name axes after the
BOM `Name` column so the mapping stays traceable.

```powershell
$h = @{ Authorization = "Bearer $t"; "Content-Type" = "application/json" }
$b = "https://<host>/automation/api/v2/nodes"

$props = '{"type":"object","value":{"axsType":"ROTATIONAL","modulo":false,"moduloValue":360.0,"axsCategory":{"axsCategory":"DRIVEAXS"},"activated":true}}'
$lim   = '{"type":"object","value":{"posMin":-100000.0,"posMax":100000.0,"velPos":3000.0,"velNeg":3000.0,"acc":10000.0,"dec":10000.0,"jrkAcc":0.0,"jrkDec":0.0,"trqPos":100.0,"trqNeg":100.0}}'

1..15 | ForEach-Object {
  $n = "Motor_" + $_.ToString("00")
  Invoke-RestMethod "$b/motion/axs" -Method POST -Headers $h -Body ('{"type":"string","value":"'+$n+'"}')
  Invoke-RestMethod "$b/motion/axs/$n/cfg/properties" -Method PUT -Headers $h -Body $props
  Invoke-RestMethod "$b/motion/axs/$n/cfg/lim"        -Method PUT -Headers $h -Body $lim
}
```

- `"ROTATIONAL"` is the correct enum (confirmed again 2026-08-11) — `"ROTARY"` is rejected.
- 15 axes created back-to-back with no rate-limiting or delay needed.
- For ROTATIONAL axes positions are in **degrees**.

## 5. Boot and verify

```
POST motion/cmd/opstate  {"type":"string","value":"Booting"}
```

If `motion/state/boot-state` stalls at **step 5/18** "Wait for Scheduler callables (wait
for RUN state)", the scheduler is not in RUN — this is normal and expected, not a fault:

```
PUT scheduler/admin/state  {"type":"object","value":{"state":"OPERATING"}}
```

Motion then reaches `Running` within ~3 s and `boot-state` reads "Booting finished".

Verify the whole set rather than one axis:

```powershell
$ax = (Invoke-RestMethod "$b/motion/axs?type=browse" -Headers $h).value
foreach ($a in $ax) { (Invoke-RestMethod "$b/motion/axs/$a/state/opstate/plcopen" -Headers $h).value }
```

All axes should read `DISABLED`. Then smoke-test **one** axis: `cmd/power` true →
`STANDSTILL`, `cmd/pos-abs` → target reached, `cmd/power` false → `DISABLED`.

Always power axes off again — any axis left `STANDSTILL` blocks the next SETUP switch.

## 6. Persistence

**The created axes are not saved.** See `axis-config-persistence.md` — there is currently
no verified REST call to persist a motion configuration. Tell the user explicitly that the
profile is lost on reboot.
