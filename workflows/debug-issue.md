# Debug Issue

Use this workflow for ctrlX app, service, performance, crash, OOM, token verifier, Data Layer disconnect, and integration investigations.

## Method

1. **Identify** the affected component and observed symptom.
2. **Determine** whether the target is real or virtual.
3. **Use `ctrlx-skill_diagnosis` first** to get diagnosis workflow guidance.
4. **Read active alarms** via `ctrlx-datalayer_read("diagnosis/get/actual/list")` — gives the current alarm list instantly without logbook scanning.
5. **Read logbook** with `ctrlx-logbook_list_entries` only if more history is needed.
6. Look for system-level causes before overfocusing on noisy downstream symptoms.
7. Cross-check `reference/`, product PDFs, reusable cases under `cases/reusable/`, and known platform pitfalls.
8. Report root cause, confidence, evidence, and the next action.

## Evidence Checklists by Problem Class

### Crash / OOM
- `ctrlx-logbook_list_entries` with levels `Emergency,Alert,Critical,Error`, last 30 min
- `ctrlx-datalayer_read` → `system/resources/memory/usage`
- `ctrlx-apps_list_installed` → snap versions
- Look for: OOM-killer lines, segfaults, snap restarts

### Token Verifier Timeouts / Auth Floods
- Logbook filter: type=`Diagnosis`, level=`Warning,Error`
- Look for: repeated `token verifier` entries → symptom of overload, not root cause
- Check CPU/memory load: `system/resources/cpu`, `system/resources/memory`

### Data Layer Disconnects
- Logbook: `Critical,Error` last 15 min
- Look for: `DL_FAILED`, `provider disconnected`, snap crash preceding disconnect
- Often a downstream symptom — find which snap crashed first

### Service / App Not Starting
- `ctrlx-apps_get_details` → check `state`, `health`
- Logbook: filter by app snap name in message
- Look for: AppArmor denials (normal confinement — check if path is allowed), missing interfaces

### Performance / High Load
- `ctrlx-datalayer_read` → `system/resources/cpu/usage`, `system/resources/memory/usage`
- `ctrlx-datalayer_subscribe` → watch load over 10s
- Look for: runaway snap, subscription floods, excessive Data Layer polling

## Useful References

- `reference/best-practices/debugging-method.md`
- `reference/platform/snaps-and-confinement.md`
- `reference/apps/catalog.md`
- `cases/reusable/`
