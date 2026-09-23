# Node-RED App (ctrlx-node-red)

Verified on a real ctrlX CORE, ctrlX OS with Node-RED `4.1.11-ctrlx` (snap `ctrlx-node-red`, revision 1786), 2026-09-22.

## Access and authentication

- Editor and Admin API: `https://<ip>/node-red/` (also `httpNodeRoot`).
- The normal ctrlX bearer token from `POST /identity-manager/api/v2/auth/token` is accepted directly by
  the Node-RED Admin API. No separate Node-RED login is needed.
- `GET /node-red/settings` shows version, user permissions and runtime settings.
- Automation of flows, context and injects: see `recipes/node-red/admin-api-flows.md`.

## Paths

| What | Path |
|---|---|
| userDir (flows.json, package.json, node_modules, context) | `/var/snap/ctrlx-node-red/current/solutions/activeConfiguration/node-RED` |
| same via WebDAV | `https://<ip>/solutions/webdav/appdata/node-RED/` |
| same inside a Function node | `env.get("SNAP_DATA") + "/solutions/activeConfiguration/node-RED"` |
| Node-RED runtime (read-only) | `/snap/ctrlx-node-red/current/lib/node_modules/` |
| settings.js (read-only) | `/snap/ctrlx-node-red/current/settings.js` |
| HOME of the process | `/root/snap/ctrlx-node-red/<rev>` |

`SNAP_COMMON` (`/var/snap/ctrlx-node-red/common`) only contains `package-certificates`, not the userDir.

Files placed by the customer in the userDir (for example a `config/` subfolder with JSON files) are
reachable both via WebDAV and from Function nodes via `fs`. The `watch` node works on that folder.

## Palette nodes observed on a customer device

Palette-installed modules are packed as `.tgz` under `userDir/nodes/` and referenced in
`userDir/package.json` with `file:` specs. Example: `node-red-contrib-s7 3.1.3`,
`node-red-contrib-influxdb 0.7.0`. Preinstalled: `node-red-contrib-ctrlx-automation`,
`@flowfuse/node-red-dashboard`, `node-red-dashboard`, `node-red-node-ping`, `node-red-node-random`,
`node-red-node-serialport`.

## Function node sandbox (differs from a standard Node-RED install)

- `process` is **not defined** (no `process.env`, `process.cwd()`), `require` is not available.
- Environment variables: `env.get("SNAP_DATA")`, `env.get("SNAP")`, `env.get("HOME")` etc. work.
- Built-in modules (`fs`, `net`, `os`, `crypto`, `path`) can be used via the node's `libs` (Setup tab).
- `functionExternalModules: true`, `functionTimeout: 0`.
- External modules: only modules listed in `userDir/package.json` dependencies and present in
  `userDir/node_modules/<name>` can be loaded. Modules bundled inside a palette package
  (for example `@st-one-io/nodes7` inside `node-red-contrib-s7`) must be registered first:
  see `recipes/node-red/function-module-from-palette.md`.

## Gotchas

- **One unknown Function module blocks all flows.** If an enabled Function node lists a module in `libs`
  that is not in `userDir/package.json`, Node-RED tries `npm install` on deploy. Offline this fails and
  the runtime starts no flow at all (`/node-red/flows/state` still says `start`, nothing runs).
  Disabled nodes (`"d": true`) are skipped by the dependency check.
- `http request` node: `senderr: true` means "send errors **only** to a Catch node". For evaluating
  `msg.statusCode` on the output (including connection errors like `ECONNREFUSED`), use `senderr: false`.
- Context stores on this device: `memoryOnly` (default) and `file`. Use `file` for state that must
  survive restarts (for example buffer cursors).
- The legacy folder `userDir/externalModules/` is not used by Node-RED 4 and triggers a warning; do not create it.

## Related

- `recipes/node-red/admin-api-flows.md`
- `recipes/node-red/function-module-from-palette.md`
- `recipes/node-red/s7-to-rest-with-influx-buffer.md`
- `cases/reusable/node-red-s7-rest-buffer/CASE.md`
