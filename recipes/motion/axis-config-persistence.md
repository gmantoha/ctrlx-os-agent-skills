# Motion Configuration Persistence (UNRESOLVED via REST)

Status: **open problem**, ctrlX OS 4.6 virtual, investigated 2026-08-11.

Axes created via REST are held in the running Motion instance only. They survive a
Configuration → Running cycle, but there is **no verified REST call to persist them**.
Assume axes are lost on reboot until this is solved.

## The nodes exist

```
GET motion/admin/cfg?type=browse
→ load, load-async, load-save-async-state, make-persistent, save, save-async
```

| Node | Description (from metadata) |
|------|------------------------------|
| `motion/admin/cfg/save` | "save data of the whole ctrlX MOTION" |
| `motion/admin/cfg/make-persistent` | "Make changes of a single motion object persistent" |

Both take `createType = types/datalayer/persistence_param` and return
`createOutType = types/datalayer/string`.

## What was tried and what happened

`POST motion/admin/cfg/save`:

| Body | Result |
|------|--------|
| `{"type":"object","value":{}}` | 500 `090F0054` / `0C570101` "Invalid parameter", `DL_SUBMODULE_FAILURE` |
| `{"type":"object","value":{"path":"..."}}` | 400 `DL_TYPE_MISMATCH` — `unknown field: path` |
| `{"type":"object","value":{"name":"..."}}` | 400 `DL_TYPE_MISMATCH` — `unknown field: name` |
| `{"type":"object","value":{"phase":"SAVE"}}` | 500 "Invalid parameter" |
| `phase` = `SAVE_ALL`, `ALL`, `PERSIST`, `STORE`, `save`, `Save`, `CONFIG`, `ACTIVE` | all 500 "Invalid parameter" |

`POST motion/admin/cfg/make-persistent` with `{"type":"bool8","value":true}` → 408 `DL_TIMEOUT`.

**Key diagnostic:** `phase` is the *correct field name* — it passes schema validation where
`path` and `name` are rejected outright. Only the enum **value** is wrong. The remaining
unknown is the accepted value set for `phase`.

Note the two distinct error classes, they tell you different things:

- **400 `DL_TYPE_MISMATCH` + `unknown field: X`** → the field name is wrong.
- **500 `Invalid parameter`** → field name accepted, value rejected.

Do not read the 500 as "this node doesn't work".

## Also unresolved

`motion/axs/{name}/cfg/save` — 500 with `{"phase":"SAVE"}`, 408 with a plain string
(2026-08-11). Same open question.

## How to solve this

Use `workflows/learn-from-ui.md`: run a Data Layer Diff while clicking **Save** in the
Motion UI, and read the payload the UI actually sends. Do not guess further enum values —
the eight tried above cover the obvious candidates and all failed.

If you resolve it, replace this file with the working call.
