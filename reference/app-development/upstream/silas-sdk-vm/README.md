# Silas SDK VM Source Snapshot

This directory preserves the generalizable ctrlX app-build subset of
`vitalisAutomation/kuschke-silas-bachelor-thesis` before the upstream
repository is removed.

## Provenance

- Upstream repository:
  `https://github.com/vitalisAutomation/kuschke-silas-bachelor-thesis`
- Upstream commit:
  `41927dc373366abb478a6b3fc1ccdb8c4ed72751`
- Commit date: `2026-09-15T08:08:46+02:00`
- License: MIT; see `LICENSE`.
- Import method: exact Git blobs from the upstream commit, not copied from a
  generated package or VM.

Preserved files:

| File | Git blob |
|---|---|
| `LICENSE` | `6311cf628de708e4928998fcf09ad3286def64b7` |
| `build-snap-amd64.sh` | `3ea08629fa5575568cb7b4b458b557fc24ef5df2` |
| `build-snap-arm64.sh` | `48a0fa436dc1feb1de5b570a538d234af9ce0a92` |
| `sdk-vm-automation/install_sdk.bat` | `b6408f851775311634ca1935dc21ef7dc1a907f7` |
| `sdk-vm-automation/docs/flowchart.mmd` | `b196ec1149a38243562ccb0aaa4ca27ce734f54c` |

The upstream README, Raspberry Pi/device workflows, generated PDFs/SVGs,
compiled snaps, certificates, VM images, and generated documentation are not
vendored. Their app-build lessons are summarized in
[`recipes/app-build/windows-qemu-sdk-vm.md`](../../../../recipes/app-build/windows-qemu-sdk-vm.md).

## Archive, Not Runnable Default

The source is preserved for study and a future hardened rebuild. Do not run
`install_sdk.bat` unchanged on a trusted workstation. At this revision it:

- downloads mutable installers, cloud images, the SDK `main` branch, and the
  ctrlX skill default branch without a complete checksum/pinning policy;
- uses `curl -k`, `wget --no-check-certificate`, and disables Git TLS
  verification during provisioning;
- creates a known VM password, enables SSH password authentication and
  passwordless sudo, and disables SSH host-key checking;
- accepts a Bosch password for CNTLM, Base64-encodes it in the Windows process,
  and expands that value into the generated Cloud-Init provisioning script
  before deriving the CNTLM hash in the guest.

Consequently, generated `instances/cidata/user-data`, `seed.iso`, VM images,
logs, and process state can contain credential material. The local
`.gitignore` blocks common generated artifacts, but it is not a security
boundary. Use throwaway credentials only during a hardened redesign, inspect
generated files, and remove them securely after testing.

The official, version-matched Bosch Rexroth SDK documentation, ctrlX WORKS ABE,
standalone QEMU launchers, and samples remain authoritative.

## Verify the Snapshot

From the repository root:

```bash
git hash-object reference/app-development/upstream/silas-sdk-vm/LICENSE
git hash-object reference/app-development/upstream/silas-sdk-vm/build-snap-amd64.sh
git hash-object reference/app-development/upstream/silas-sdk-vm/build-snap-arm64.sh
git hash-object reference/app-development/upstream/silas-sdk-vm/sdk-vm-automation/install_sdk.bat
git hash-object reference/app-development/upstream/silas-sdk-vm/sdk-vm-automation/docs/flowchart.mmd
```

The hashes must match the manifest above.
