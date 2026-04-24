# Architecture

ctrlX OS is an app platform built around isolated snaps, shared system services, and the ctrlX Data Layer as a common IPC layer.

Useful mental model:

- apps are isolated deployment units
- device services expose functions through REST and/or Data Layer
- many integrations differ depending on whether the caller is inside or outside the device
