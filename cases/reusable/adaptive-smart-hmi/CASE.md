# Case: Adaptive Smart HMI across PLC contracts

## Use When

Use this case when a read-only ctrlX web HMI must support more than one PLC
application, a project-specific symbol contract is being mistaken for a
platform contract, or a Windows preview/build workflow behaves differently
from the browser or deployment target.

## Problem

A dependency-free Python REST/Data Layer adapter originally assumed one
published PLC axis contract and independently displayed Motion axes. A second
PLC template published `GVL_BASE`, `GVL_CORE`, `GVL_CUSTOMER`, and
`GVL_EtherCAT`, but did not publish the legacy axis group or selector. The HMI
also had a local login fetch error, a phantom numeric Axis 1 in traces, and
two project copies that could be confused during preview and packaging.

## Verified Findings

### PLC profile and overview

The PLC profile is inferred from the bounded browse of
`/plc/app/Application/sym`, not from the PLC project name:

- `legacy_axis_interface` requires `GVL_HMI/Axis_HMI`;
- `plc_template` requires `GVL_BASE` plus `GVL_CORE` and/or `GVL_EtherCAT`;
- `unknown` means the root browse succeeded but neither specialized contract
  was confirmed.

Motion discovery is independent under `/motion/axs`. A valid PLC profile can
have no Motion axes, and Motion can be available when no supported PLC profile
exists.

The tested template publishes alarm arrays as `arAppAlarm`, `arAppInfo`, and
`arAppWarn`. A robust adapter maps these to logical alarms/info/warnings while
retaining direct aliases when another template uses them. Missing optional
fields, wrong types, bounded browse failures, and read errors stay attached to
the response as diagnostics.

`GVL_CORE` and `GVL_EtherCAT` names used by one PLC program are not universal
CORE health. The generic HMI should not require or promote them as dedicated
Machine health blocks. Use ctrlX OS system APIs for verified system metrics
when available, and use a bounded read-only Data Layer Explorer for
project-specific symbols.

### Motion and UI behavior

The correct Motion flow is:

1. browse `/motion/axs` whenever Operate or Signal traces opens;
2. use the returned safe axis names;
3. read one axis through a name-safe per-axis route;
4. display units from the published Motion data;
5. enforce direction-specific velocity limits before sending a typed command.

Do not convert a Motion name into a numeric PLC axis index. The phantom Axis 1
was caused by a default `selectedIndex = 1`, accepting an unvalidated server
selector, and polling the legacy state route when no legacy record existed.
Use an empty/unavailable state until a real record is discovered. Keep PLC axis
details visible only for the legacy contract and keep Operate axes and Signal
traces as the two clear Motion views.

### Local preview diagnosis

Browser `Failed to fetch` was caused by the local HMI backend not listening on
the port used by the browser, not by invalid CORE credentials. The reliable
diagnostic order is:

1. compare browser URL and process listener port;
2. request `/`;
3. request `/api/auth/session`;
4. confirm the process cwd/source copy;
5. inspect CORE auth/TLS only after the local server is healthy.

The local virtual CORE used a self-signed certificate, so
`CTRLX_TLS_VERIFY=false` was appropriate for the local preview only. Device
certificate settings and credentials were not changed.

### Windows build and package separation

When Windows lacked Snapcraft, Docker, and a usable WSL distribution, the
working path was a ctrlX WORKS App Build Environment (ABE) with SSH forwarding
from host port 10022 to VM port 22. The ABE launcher had to run from its
configured instance directory because its batch file used relative image and
seed paths. A TCP-open check was insufficient; SSH login and
`snapcraft --version` confirmed readiness.

Stable and newer HMI variants were synchronized and built in separate ABE
directories, then copied to separate Windows artifact folders. Each package
was inspected with `snap info` and `unsquashfs` before any deployment. The
temporary ABE was powered off afterward; the existing virtual CORE endpoints
remained unchanged. No snap installation was implied by a successful build.
The preserved examples used `smart-hmi` with `/smart-hmi/` and `axis-hmi` with
`/axis-hmi/`; their technical identifiers and socket paths must remain distinct
even when both user-facing pages are branded Smart HMI.

The public
`https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis` repository
is a useful secondary reference for a Windows SDK VM and
architecture-specific cross-compilation, but the official SDK and configured
ABE remain the source of truth.

## Reusable Resolution

Implement the HMI as a bounded discovery/adaptation layer:

- classify the published PLC contract;
- keep Motion, Explorer, and OS health as separate capabilities;
- normalize only verified fields and aliases;
- gate navigation and polling from capabilities;
- keep writes allow-listed, typed, acknowledged, and authorized by CORE;
- use fakes and regression tests rather than a real CORE during development;
- keep canonical source, runtime process, ABE build tree, and snap artifacts
  distinct.

## Validation Checklist

Before handoff, run the existing Python compilation/tests and JavaScript syntax
check, then inspect the snap name/version/architecture/base/confinement,
launcher, package manifest, reverse-proxy route, socket path, and staged web
assets. Record the source revision and artifact hash. For a virtual target,
check its status before and after; for a real CORE, inspect first and obtain
explicit confirmation before installation, restart, or configuration changes.
