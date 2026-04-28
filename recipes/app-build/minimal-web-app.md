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
4. Add the `configs` part and `package-assets` slot.
5. Prefer a Unix socket reverse-proxy binding and expose it with `package-run`.
6. Declare only the scopes the service enforces.
7. Add menu entries only for UI entry points that should appear in ctrlX OS.
8. Build and inspect snap contents before installation.
9. On a real device, ask before installing or updating the app.

## Local References

- `reference/app-development/snap-packaging.md`
- `reference/app-development/package-assets.md`
- `reference/app-development/troubleshooting.md`

## Verification

```bash
snapcraft pack --build-for=amd64 --destructive-mode --verbosity=verbose
snap info ./my-app_1.0.0_amd64.snap
unsquashfs -l ./my-app_1.0.0_amd64.snap | grep package-assets
python3 -m json.tool configs/package-assets/<snap-name>.package-manifest.json
```

On the target, verify service state, Logbook entries, UI route, reverse-proxy route, and `snap connections <snap-name>`.
