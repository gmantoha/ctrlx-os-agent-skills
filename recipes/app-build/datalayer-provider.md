# Data Layer Provider Snap

Use this recipe when creating or debugging a snap that registers nodes in the ctrlX Data Layer.

## Source Priority

Check these first:

- `reference/app-development/sources.md`
- SDK Data Layer docs: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/datalayer.html
- SDK samples: https://boschrexroth.github.io/ctrlx-automation-sdk/4.6.0/samples.html
- SDK GitHub repository: https://github.com/boschrexroth/ctrlx-automation-sdk

## Design Checklist

1. Confirm the node tree, operations, metadata, and payload types.
2. Choose the SDK language based on official sample quality and project constraints.
3. Confirm whether the app is a provider, client, or both.
4. Use `ipc://` inside snap runtime.
5. Add the `datalayer` content interface only when the app needs it.
6. Install SDK Data Layer build packages through official SDK scripts when staging or linking SDK libraries.
7. Keep provider request handling stateless and follow the documented operation semantics.
8. Build for the target architecture and inspect the snap before device install.
9. On a real device, ask before installing, updating, restarting, or changing the app.

## Local References

- `reference/app-development/datalayer-apps.md`
- `reference/app-development/snap-packaging.md`
- `reference/app-development/troubleshooting.md`
- `workflows/use-datalayer.md`

## Verification

```bash
snapcraft pack --build-for=amd64 --destructive-mode --verbosity=verbose
snap connections <snap-name>
sudo snap logs <snap-name> -n 100
```

Verify the registered nodes by browsing and reading the Data Layer paths through the appropriate client, REST API, PLC code, or SDK tool for the scenario.
