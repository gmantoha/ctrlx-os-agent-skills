# Use Web UI

Use this workflow for UI-driven ctrlX tasks and Playwright-backed validation.

## Required Behavior

- Capture exact navigation paths, settings, and expected outcomes.
- Prefer UI workflows for guided persistent configuration when available.
- On real devices, ask before saving persistent changes.
- Use Playwright when repeatable browser validation, screenshots, or form workflows are needed.

## Standard Flow

1. Identify the target URL, credentials, and real/virtual status.
2. Navigate to the relevant app or settings area.
3. Inspect current values before changes.
4. Propose UI changes before saving on real devices.
5. Save only after confirmation when required.
6. Verify the UI state and any underlying service behavior.
