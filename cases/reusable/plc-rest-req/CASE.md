# Case: USB Mount from ctrlX PLC

## Use When

Use this case when a customer asks how to mount or unmount USB storage from ctrlX PLC Engineering or asks whether PLC code should call ctrlX REST APIs directly.

## Symptoms / Question

- Customer wants HTTP REST calls from PLC Structured Text.
- Customer wants to mount or unmount USB storage from PLC logic.

## Key Finding

For USB mount operations on ctrlX OS 4.4 or newer, PLC code should use the ctrlX Data Layer via `CXA_DataLayer` instead of direct HTTP/REST. The relevant nodes are `system/resources/tasks/storage/mountDevice`, `system/resources/tasks/storage/unmount`, and `system/resources/storage`.

## Details

See `ANSWER.md`, `references.md`, and `recipes/plc/usb-mount-via-datalayer.md`.
