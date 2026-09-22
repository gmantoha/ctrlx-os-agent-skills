# Snap App From Idea

Use this recipe when turning a new ctrlX CORE application idea into an
editable source tree and an installable snap. It applies to web apps, daemons,
Data Layer clients/providers, gateways, monitoring tools, and mixed apps.

## Choose the app shape

| App shape | Runtime contract | Typical interfaces |
| --- | --- | --- |
| Web UI or HTTP API | Long-running daemon behind package-assets | `network`, `network-bind`, `package-assets`, `package-run` |
| Data Layer client | Reads, writes, browses, or calls existing nodes | `datalayer` |
| Data Layer provider | Registers and serves its own nodes | `datalayer` |
| Mixed app | Web/API plus Data Layer integration | Only the interfaces used by each part |
| Worker or gateway | Long-running background process | `network` and any protocol-specific interface actually required |
| One-shot utility | Explicit command or job | No daemon unless the platform workflow requires one |

Do not add an interface because an example has it. Confirm the required
operation, target OS support, and official SDK sample first.

## Fast implementation flow

1. Define the app's input/output contract, target architecture, base, runtime,
   persistence needs, and whether any operation can change machine state.
2. Select the closest official SDK sample for the language and app shape.
3. Keep source easy to edit and split UI, service, integration, and
   configuration concerns.
4. Add a minimal strict-confinement `snapcraft.yaml` with a daemon only when
   the process must stay alive.
5. Add package-assets/package-run only for a web route, `datalayer` only for
   Data Layer access, and `licensing-service` only for actual device-license
   acquisition.
6. Keep secrets server-side or in the target's supported secret/configuration
   mechanism. Never ship credentials, tokens, private keys, or developer
   paths.
7. Add fake-client or contract tests for reads, writes, missing capabilities,
   error status, and payload/type validation. Do not test machine-changing
   commands against a real CORE.
8. Run the smallest relevant tests and syntax checks.
9. If a snap is requested, start the configured ctrlX WORKS ABE automatically,
   synchronize the canonical source once, build only the active architecture,
   inspect the snap, and run a packaged runtime smoke test.
10. Obtain confirmation before installing or changing the app on a real CORE.

## Generic snap preflight

Before building, confirm:

- `base` matches the target ctrlX OS release (`core22` versus `core24` is not
  interchangeable);
- architecture matches the target (`arm64` for the active physical target,
  `amd64` for a matching virtual target);
- the launcher is executable, uses an available runtime interpreter, and has
  LF line endings;
- daemon, restart policy, plugs, slots, and persistence paths are intentional;
- package-assets `id`, route, proxy mapping, socket, and `package-run` paths
  agree for web apps;
- Data Layer provider/client roles and node schemas are documented;
- no false device-license declaration is present;
- version and artifact name are new for the build being tested.

## Verification layers

Use evidence in this order:

1. Unit and contract tests with fake integrations.
2. Snap metadata/content inspection (`snap info`, `unsquashfs -l`, manifest
   validation).
3. Packaged launcher and service smoke test in the ABE.
4. Matching virtual CORE, when available.
5. Real CORE service, interface, log, and route verification after explicit
   installation approval.

A successful source build proves neither target architecture compatibility nor
target confinement. A successful ABE socket test proves neither Data Layer
permissions nor a real-device license.

## Boundaries that need extra design

- Native libraries, GPU/AI runtimes, and hardware drivers need target
  architecture and confinement review.
- Device configuration, PLC downloads, motion, network changes, and other
  persistent operations need a separate safety workflow.
- Store release, signing, stable grade, update channels, and commercial
  licensing are release work beyond a local development snap.
- Third-party repositories can explain build mechanics but do not replace
  official SDK documentation or target-side evidence.
