# Install or update a local snap on ctrlX CORE

Use this recipe when a locally built `.snap` must be installed or updated on
a real ctrlX CORE through the documented REST API. It complements
`workflows/manage-apps.md` and the ABE build recipe; it does not replace the
required confirmation before changing a real device.

## Preconditions

- Confirm the target CORE address, target architecture, snap name, and package
  version.
- Inspect the installed package with `GET /package-manager/api/v1/packages`.
- Read and record the current scheduler state from
  `GET /automation/api/v2/nodes/scheduler%2Fadmin%2Fstate`.
- Obtain explicit user confirmation before changing SERVICE/OPERATING mode or
  uploading the package.
- Keep credentials, bearer tokens, portal cookies, and upload logs out of
  source control and command output.

## Upload

Authenticate with `POST /identity-manager/api/v2/auth/token`, then switch to
SERVICE mode with:

```json
{"type":"object","value":{"state":"SERVICE"}}
```

Upload the local snap as multipart form data. The `update=true` field is
required when replacing an installed snap:

```powershell
curl.exe --noproxy "*" -k -X POST `
  "https://<core>/package-manager/api/v1/packages" `
  -H "Authorization: Bearer <token>" `
  -F "file=@C:\path\to\app_<version>_<arch>.snap" `
  -F "update=true"
```

The expected response is HTTP 202. Do not treat the returned task state as
completion evidence.

## Completion and mode restoration

Poll `GET /package-manager/api/v1/packages` every five seconds until the
target snap reports the requested `release.version` and `installed: true`.
Restore the scheduler's original state, normally OPERATING, after the package
reaches the target version. Device Admin may briefly reject the transition
while installation is still active; wait and retry rather than leaving the
device in SERVICE mode.

## Verification

Verify all of the following after restoring the original mode:

- package version, `installed`, and `enabled` state;
- public web route returns HTTP 200;
- installed-mode authentication uses the forwarded
  `CTRLX-OS-SESSION-ID` cookie and a server-side Identity Manager exchange;
- the app's read-only API returns real target data;
- an event-stream endpoint returns its initial snapshot/keepalive;
- service logs show no startup, socket, or permission failure.

For package-assets web snaps, test the public route under its full prefix
(`/<snap-name>/api/...`), not only `/api/...`. A root-level portal response can
be HTTP 200 HTML and still hide a wrong API path in browser JavaScript.

## Failure boundaries

- 401 from the app API: inspect the portal cookie name/value and the
  Identity Manager cookie exchange; do not create an unauthenticated
  success-shaped session.
- 200 HTML where JSON is expected: check that browser requests include the
  package public prefix.
- Empty axis data: authenticate first, then read the raw
  `/automation/api/v2/nodes/motion/axs?type=browse` response before changing
  Motion discovery logic.
- 502 or initialization page: inspect snap service state, interfaces, exact
  package-run socket, package-assets mapping, and logs separately.
