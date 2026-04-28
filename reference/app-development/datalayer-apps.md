# Data Layer Apps

Use Data Layer for in-device communication between snaps, PLC code, and ctrlX services. Use REST for external clients unless an on-device Data Layer integration is explicitly required.

Primary sources:

- Data Layer docs: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/datalayer.html
- SDK samples: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/samples.html
- SDK GitHub repository: https://github.com/boschrexroth/ctrlx-automation-sdk

## App Decisions

Identify whether the app is a Data Layer client, provider, or both.

- Client: reads, writes, browses, or calls existing nodes.
- Provider: registers nodes and handles provider callbacks.
- Mixed: exposes own nodes and consumes other service nodes.

For provider implementation details, prefer official SDK samples for the selected language. Local snippets are fallback only.

## Build Dependencies

The official SDK setup is the source of truth. For local diagnostics, Data Layer builds often require:

```bash
sudo apt-get update && sudo apt-get install -y \
    snapcraft \
    pkg-config \
    libsystemd-dev \
    libzmq3-dev \
    gcc
```

Cross-building CGO-based Go or native components for `arm64` commonly also requires:

```bash
sudo apt-get install -y gcc-aarch64-linux-gnu
```

Install the SDK Data Layer Debian package through the official SDK scripts when `ctrlx-datalayer` is needed as a build or stage package.

## snapcraft Interface

Data Layer access uses the `datalayer` content interface:

```yaml
plugs:
  datalayer:
    interface: content
    content: datalayer
    target: $SNAP_DATA/.datalayer

apps:
  app:
    plugs:
      - datalayer
```

If the app stages the SDK Data Layer package, check the current SDK sample for exact package and lint handling.

## Connection Pattern

Inside a snap, use IPC. Outside a snap, use the connection scheme appropriate for the target and SDK sample.

```text
snap runtime: ipc://
development: tcp://<user>:<password>@<host>?sslport=<port>
```

Do not hard-code non-default credentials in tracked files. Public default credentials may appear in examples only when intentionally documenting a lab or default setup.

## Provider Semantics

Provider functions follow the Data Layer operation model from the official docs:

| Function | Purpose | Safe | Idempotent |
| --- | --- | --- | --- |
| `onCreate` | Create an object | No | No |
| `onRemove` | Remove an object | No | Yes |
| `onBrowse` | Browse child nodes | Yes | Yes |
| `onRead` | Read node value | Yes | Yes |
| `onWrite` | Change node value | No | Yes |
| `onMetadata` | Read metadata | Yes | Yes |

Requests should be stateless. Do not store client request context on the provider between requests.

## Runtime Verification

On a target device, inspect before changing persistent state:

```bash
snap connections <snap-name>
sudo snap logs <snap-name> -n 100
```

On real devices, ask before installing, updating, restarting, or changing app configuration.
