# Start a Virtual ctrlX CORE with QEMU on Windows

Verified on Windows on 2026-11-11 with ctrlX OS **4.6.5**, ctrlX WORKS **4.6.1**
and its bundled QEMU **11.0.50**, using PowerShell 7. These are verified settings
for this combination, not requirements for every ctrlX image or QEMU version.

Follow `workflows/use-virtual-core.md` and `labs/ctrlx-os-virtual/AGENTS.md`.
This procedure operates a local virtual lab, not a real ctrlX device.

## Working Settings

| Setting | Verified value |
| --- | --- |
| QEMU executable | `qemu-system-x86_64.exe` bundled with ctrlX WORKS |
| Accelerator | `-accel tcg,thread=multi` (software emulation) |
| CPU / memory | `-cpu max -smp 4 -m 2048` |
| Disk | QCOW2 overlay, `if=ide,format=qcow2` |
| System disk parameter | `snapd_system_disk=/dev/sda` |
| Network adapter | `-net nic,model=e1000` |
| Consoles | `console=tty1 console=ttyS0` (serial last for boot diagnostics) |
| Display / monitor | `-display none -monitor none` |
| Web UI | `https://127.0.0.1:8443` forwarded to guest TCP 443 |
| Other forwards | TCP 8022 -> 22, 8740 -> 11740, 4840 -> 4840, 2069 -> 2069, 2070 -> 2070 |
| QMP management | `tcp:127.0.0.1:4446,server=on,wait=off` |

The Linux launcher uses KVM and `-cpu host`; do not run it unchanged on Windows.
TCG worked without an active Windows hypervisor. WHPX was not tested; do not enable
Windows features or reboot the host just to follow this recipe. Software-emulated
CPU measurements are not directly comparable to physical ctrlX CORE performance.

## 1. Check Status and Discover Files

Report whether a VM is already running before starting anything:

```powershell
Get-CimInstance Win32_Process |
    Where-Object Name -Like 'qemu-system*' |
    Select-Object Name, ProcessId, CommandLine

Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object LocalPort -In 8022, 8443, 8740, 4840, 2069, 2070, 4446 |
    Select-Object LocalAddress, LocalPort, OwningProcess
```

Inspect the command line and local `assets/runtime/*.state.json` files to identify
the intended lab and overlay. A saved PID alone is not proof: Windows can reuse PIDs.
Do not terminate another VM or launch a second instance against an in-use disk/port.
Git Bash `kill -0` and the Bash PID files do not reliably manage native Windows QEMU.

Find the installed QEMU and image version; do not assume the Bash default `4.6.0`.
The image directory must contain `kernel.img`, `initrd.img` and
`virtual-control.base.qcow2`. Example variables for a global OpenCode installation:

```powershell
$WorksVersion = '4.6.1' # Adjust to the installed ctrlX WORKS version.
$ImageVersion = '4.6.5' # Adjust to the actual local image directory.
$QemuDir = Join-Path $env:ProgramFiles "ctrlX WORKS\ctrlX WORKS\$WorksVersion\qemu"
$Lab = Join-Path $HOME '.config\opencode\skills\ctrlx\labs\ctrlx-os-virtual'
$Image = Join-Path $Lab "assets\$ImageVersion"
$Runtime = Join-Path $Lab 'assets\runtime'
$Qemu = Join-Path $QemuDir 'qemu-system-x86_64.exe'
$QemuImg = Join-Path $QemuDir 'qemu-img.exe'
```

For other skill installation locations, set `$Lab` to that installation's lab
directory. Validate every executable/image path and ensure the listed ports are
free before proceeding. No workstation-specific absolute path belongs in shared docs.

## 2. Protect the Base Image and Preserve State

Keep images, overlays, logs and process metadata under the ignored lab `assets/`
directory. On restart, set `$Overlay` to the **existing inspected overlay** from
the lab's runtime state. Reuse it to preserve the initialized guest and its settings.
Never silently replace an existing lab with a fresh overlay.

For a deliberately new lab only:

```powershell
New-Item -ItemType Directory -Path $Runtime -Force | Out-Null
$Overlay = Join-Path $Runtime "$ImageVersion.windows-lab.qcow2"
if (Test-Path -LiteralPath $Overlay) {
    throw 'Overlay already exists; inspect and reuse it instead of overwriting it.'
}
& $QemuImg create -f qcow2 -F qcow2 `
    -b (Join-Path $Image 'virtual-control.base.qcow2') $Overlay
if ($LASTEXITCODE -ne 0) { throw 'Could not create the overlay.' }
```

Do not launch a second writer against an existing overlay or change the backing
image while any VM uses it. Starting and stopping this lab does not require changing
the ctrlX WORKS virtual-control registrations or any real-device configuration.

## 3. Start Native Windows QEMU

Use the validated variables and the new or existing `$Overlay` selected above.
All forwards, including the unauthenticated QMP management port, bind to loopback.

```powershell
$Tag = "$ImageVersion-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$Serial = Join-Path $Runtime "$Tag.serial.log"
$QemuLog = Join-Path $Runtime "$Tag.qemu.log"
$Stdout = Join-Path $Runtime "$Tag.stdout.log"
$KernelArgs = 'earlycon clk_ignore_unused rng_core.default_quality=700 panic=-1 ' +
    'systemd.unified_cgroup_hierarchy=0 snapd_recovery_mode=run ' +
    'snapd_system_disk=/dev/sda console=tty1 console=ttyS0 net.ifnames=0 ' +
    'usage=evaluation ctrlx-fpga-virtual.virtual=1 ctrlx-ecm.port1=XF50'
$Network = 'user,hostfwd=tcp:127.0.0.1:8022-:22,' +
    'hostfwd=tcp:127.0.0.1:8443-:443,hostfwd=tcp:127.0.0.1:8740-:11740,' +
    'hostfwd=tcp:127.0.0.1:4840-:4840,hostfwd=tcp:127.0.0.1:2069-:2069,' +
    'hostfwd=tcp:127.0.0.1:2070-:2070'
$QemuArgs = @(
    '-display', 'none', '-monitor', 'none'
    '-accel', 'tcg,thread=multi', '-cpu', 'max', '-smp', '4', '-m', '2048'
    '-kernel', (Join-Path $Image 'kernel.img')
    '-initrd', (Join-Path $Image 'initrd.img')
    '-drive', "file=$Overlay,if=ide,format=qcow2"
    '-net', 'nic,model=e1000', '-net', $Network
    '-serial', "file:$Serial"
    '-qmp', 'tcp:127.0.0.1:4446,server=on,wait=off'
    '-append', $KernelArgs
)
# Start-Process joins ArgumentList; quote each argument to preserve paths with spaces
# and pass the entire kernel command line as a single argument.
$QuotedArgs = $QemuArgs | ForEach-Object { '"' + $_ + '"' }
$Vm = Start-Process -FilePath $Qemu -ArgumentList $QuotedArgs `
    -WorkingDirectory $QemuDir -RedirectStandardOutput $Stdout `
    -RedirectStandardError $QemuLog -PassThru
$StateFile = Join-Path $Runtime "$Tag.state.json"
[pscustomobject]@{
    ProcessId = $Vm.Id
    StartTime = (Get-Date).ToString('o')
    Overlay = $Overlay
    SerialLog = $Serial
    QemuLog = $QemuLog
    WebUrl = 'https://127.0.0.1:8443'
    QmpPort = 4446
    VirtualCpus = 4
    MemoryMB = 2048
    Accelerator = 'TCG'
    DiskInterface = 'IDE'
    NetworkModel = 'e1000'
    SystemDiskParameter = 'snapd_system_disk=/dev/sda'
} | ConvertTo-Json | Set-Content -LiteralPath $StateFile -Encoding utf8
```

Use unique log names rather than overwriting evidence from earlier starts.
Record an explicit keep-running request in local runtime state as well.

## 4. Wait for the Login, Not Just HTTPS

A listening forwarded port, completed TLS handshake or the Bash wait script's
successful `curl` is not proof that the guest applications are ready. During boot
the reverse proxy may return HTTP 503 and **Waiting for app to start**.

```powershell
$Base = 'https://127.0.0.1:8443'
$Deadline = (Get-Date).AddSeconds(240)
do {
    if (-not (Get-Process -Id $Vm.Id -ErrorAction SilentlyContinue)) {
        throw "QEMU exited; inspect $QemuLog and $Serial"
    }
    try {
        $Web = Invoke-WebRequest $Base -SkipCertificateCheck -NoProxy `
            -SkipHttpErrorCheck -TimeoutSec 5
        $Identity = Invoke-WebRequest "$Base/identity-manager/api/v2/auth/token" `
            -SkipCertificateCheck -NoProxy -SkipHttpErrorCheck -TimeoutSec 5
        if ([int]$Web.StatusCode -eq 200 -and [int]$Identity.StatusCode -eq 401) {
            break
        }
    } catch { Write-Verbose $_.Exception.Message }
    if ((Get-Date) -ge $Deadline) { throw 'Login not ready; inspect the VM logs.' }
    Start-Sleep -Seconds 5
} while ($true)
```

HTTP **401** from the unauthenticated identity request is expected and shows that
authentication is ready; this check creates no login sessions. The certificate
exception above is only for this known local lab's self-signed HTTPS certificate,
not a reason to disable global TLS verification.

Give the user `https://127.0.0.1:8443` and the documented public lab defaults from
`labs/ctrlx-os-virtual/README.md`. Do not change credentials just to test access.
For device diagnostics, check MCP availability first and follow the relevant workflow.

## 5. Lifecycle and Graceful Shutdown

- For an explicit request to use the Web UI after startup, **leave the VM running**
  and report that final state. Documentation-only tasks must not stop that VM.
- For a temporary test, shut the lab down after testing and verify the final status.
- Verify the PID, executable and overlay in the current native command line before
  sending any management command. Do not use a stale PID to stop an unrelated process.
- For graceful shutdown, connect a local TCP client to the configured QMP port, read
  its JSON greeting, then send these newline-delimited messages in order. Match response
  IDs and check for `error`; QMP events can arrive between replies.

```json
{"execute":"qmp_capabilities","id":"caps"}
{"execute":"system_powerdown","id":"powerdown"}
```

Wait for the guest to power off and QEMU to exit (up to 90 seconds in the tested lab).
Confirm the process is gone and its forwarded ports are closed; the serial log should
show `poweroff.target` / `Power down`. Update local runtime metadata with the final
state. If graceful shutdown times out, inspect and report the state: QMP `quit` or
force-killing QEMU is not a guest shutdown and can lose unflushed disk writes.

## Troubleshooting and Evidence

- **Repeated reboot after about 90 seconds waiting for
  `dev-disk-snapd-disk.device`:** the tested VirtIO disk setup did not make the system
  disk available. `snapd_system_disk=/dev/vda` alone did not resolve it. The working
  combination used IDE, `snapd_system_disk=/dev/sda` and `e1000` networking.
  Do not assume a corrupt image or reset the disk without evidence.
- **Boot details missing from serial output:** put `console=ttyS0` last. The earlier
  order sent useful systemd diagnostics to the graphical console instead.
- **CPU check:** after login readiness and MCP detection, the documented REST fallback
  is `GET /system/api/v1/cpu`. `cpu.all.utilization` is total guest CPU percent;
  `cpu.core0` etc. are per-core values. Take multiple samples after boot settles and
  distinguish guest CPU usage from QEMU's normalized share of the Windows host CPU.
- **Verified outcome:** cold start, internal CPU readings, graceful power-off and restart
  of the same initialized overlay with a working browser login. No real-device or
  hardware-accelerated Windows behavior was tested.

Source for the explicit disk parameter:
[Ubuntu Core kernel boot parameters](https://documentation.ubuntu.com/core/reference/kernel-boot-parameters/#snapd-system-disk).
REST schemas:
[ctrlX CORE official REST APIs](https://boschrexroth.github.io/rest-api-description/ctrlx-automation/ctrlx-core/index.html).
