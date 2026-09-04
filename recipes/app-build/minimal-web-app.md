# Minimal Web App Snap

Use this recipe when creating or reviewing a ctrlX web app snap with a UI or HTTP API.

## Source Priority

Check these first:

- `reference/app-development/sources.md`
- SDK Package Assets: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/package-assets.html
- SDK samples: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/samples.html
- Snapcraft reference: https://snapcraft.io/docs/snapcraft-yaml-reference

## Integration Checklist

1. Confirm the snap name and public URL path.
2. Add only the needed app plugs, usually `network` and `network-bind`.
3. Provide `configs/package-assets/<snap-name>.package-manifest.json`.
4. Add the `configs` part and `package-assets` slot, then attach the slot to the
   intended `apps.<name>` entry.
5. Prefer a Unix socket reverse-proxy binding and expose it with `package-run`.
6. Use a unique proxy mapping name. Current official examples use both the snap
   id and `<id>.<service>` forms; this identifier is distinct from the daemon
   key under `apps`.
7. Declare only the scopes the service enforces.
8. Add menu entries only for UI entry points that should appear in ctrlX OS.
9. Build and inspect snap contents before installation.
10. On a real device, ask before installing or updating the app.

## Local References

- `reference/app-development/snap-packaging.md`
- `reference/app-development/package-assets.md`
- `reference/app-development/troubleshooting.md`

## Verification

```bash
snapcraft clean
snapcraft pack --build-for=amd64 --verbosity=verbose
snap info ./my-app_1.0.0_amd64.snap
unsquashfs -l ./my-app_1.0.0_amd64.snap | grep package-assets
python3 -m json.tool configs/package-assets/<snap-name>.package-manifest.json
```

On the target, verify service state, Logbook entries, UI route, reverse-proxy route, and `snap connections <snap-name>`.

For a development `.snap` installed through the Web UI, use **Settings ->
Apps -> Service Mode -> Install from file**, enable unknown-source installs if
required, and return to Operation Mode after installation. For an unavailable
web page, inspect the installed package version, daemon logs, package-assets
registration, proxy mapping, package-run connection, and socket path separately.
