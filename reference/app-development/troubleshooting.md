# App Build Troubleshooting

Use this page for quick triage after checking the live SDK docs and relevant SDK sample.

## Build Environment

Check installed tools and packages:

```bash
snapcraft --version
dpkg -l | grep -E "pkg-config|libsystemd-dev|libzmq3-dev|gcc-aarch64-linux-gnu"
apt-cache show ctrlx-datalayer
```

If `ctrlx-datalayer` is missing, install it through the official SDK scripts and release packages, not by guessing repository state.

## Common Build Failures

| Symptom | Likely Cause | Check |
| --- | --- | --- |
| `cannot find -lzmq` | Missing ZeroMQ development package | Install/check `libzmq3-dev` |
| `Package libzmq was not found` | Missing `pkg-config` metadata or package | Check `pkg-config` and `libzmq3-dev` |
| `libsystemd` not found | Missing systemd development package | Check `libsystemd-dev` |
| `ctrlx-datalayer` not found | SDK Debian package not installed | Use SDK install scripts/releases |
| Native module fails for `arm64` | Cross-compiler or architecture handling missing | Check SDK sample and `gcc-aarch64-linux-gnu` |
| Snapcraft/LXD timeout | Local LXD/snapd environment issue | Retry clean build or use documented destructive mode |

## Runtime Checks

Check snap service logs:

```bash
sudo snap logs <snap-name> -n 100
sudo snap logs <snap-name>.<app-name> -f
```

Check interface connections:

```bash
snap connections <snap-name>
```

Check package assets inside a snap:

```bash
unsquashfs -l ./my-app.snap
unsquashfs -l ./my-app.snap | grep package-assets
```

Validate JSON manifests before building or installing:

```bash
python3 -m json.tool configs/package-assets/<snap-name>.package-manifest.json
```

## Common Runtime Issues

| Symptom | Likely Cause | Check |
| --- | --- | --- |
| App menu missing | Manifest not packaged, invalid JSON, wrong permissions | Snap contents, browser console, Logbook |
| Reverse proxy fails | Socket not created or path too long | Socket path and `package-run` slot |
| Data Layer connection refused | Wrong connection string or disconnected interface | `ipc://` in snap, `snap connections` |
| Save/load not called | Missing package-manifest commands or wrong URL | Logbook, manifest commands, route status |
| License acquisition fails | Plug disconnected, license absent, wrong name | License docs, `snap connections`, Logbook |

## Logging

ctrlX app logs are visible via snap logs, journald, and the ctrlX Web UI Logbook. Avoid logging passwords, tokens, private keys, customer data, or personally identifiable information.
