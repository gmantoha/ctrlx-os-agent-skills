# Debug Issue

Use this workflow for ctrlX app, service, performance, crash, OOM, token verifier, Data Layer disconnect, and integration investigations.

## Method

1. Identify the affected component and observed symptom.
2. Determine whether the target is real or virtual.
3. Collect versions, installed apps, service status, recent logs, and relevant system load indicators.
4. Look for system-level causes before overfocusing on noisy downstream symptoms.
5. Cross-check `reference/`, product PDFs, reusable cases under `cases/reusable/`, and known platform pitfalls.
6. Report root cause, confidence, evidence, and the next action.

## Useful References

- `reference/best-practices/debugging-method.md`
- `reference/platform/snaps-and-confinement.md`
- `reference/apps/catalog.md`
- `cases/reusable/`
