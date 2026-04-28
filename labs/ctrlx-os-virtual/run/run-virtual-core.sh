#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

CTRLX_VM_NAME="${CTRLX_VM_NAME:-4.6.0}"
CTRLX_VM_DIR="${CTRLX_VM_DIR:-assets/$CTRLX_VM_NAME}"
CTRLX_RUNTIME_DIR="${CTRLX_RUNTIME_DIR:-assets/runtime}"
CTRLX_SSH_PORT="${CTRLX_SSH_PORT:-8022}"
CTRLX_WEB_PORT="${CTRLX_WEB_PORT:-8443}"
CTRLX_DATALAYER_PORT="${CTRLX_DATALAYER_PORT:-8740}"
CTRLX_OPCUA_PORT="${CTRLX_OPCUA_PORT:-4840}"
CTRLX_QEMU_MEMORY="${CTRLX_QEMU_MEMORY:-2048}"
CTRLX_QEMU_CPUS="${CTRLX_QEMU_CPUS:-4}"

case "$CTRLX_VM_DIR" in
  /*) VM_DIR="$CTRLX_VM_DIR" ;;
  *) VM_DIR="$LAB_DIR/$CTRLX_VM_DIR" ;;
esac

case "$CTRLX_RUNTIME_DIR" in
  /*) RUNTIME_DIR="$CTRLX_RUNTIME_DIR" ;;
  *) RUNTIME_DIR="$LAB_DIR/$CTRLX_RUNTIME_DIR" ;;
esac

PID_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.pid"
LOG_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.serial.log"
QEMU_LOG_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.qemu.log"

mkdir -p "$RUNTIME_DIR"

if [[ -f "$PID_FILE" ]]; then
  existing_pid="$(<"$PID_FILE")"
  if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "Virtual ctrlX CORE '$CTRLX_VM_NAME' is already running with PID $existing_pid."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

for required_file in kernel.img initrd.img virtual-control.base.qcow2; do
  if [[ ! -f "$VM_DIR/$required_file" ]]; then
    echo "Missing required VM image file: $VM_DIR/$required_file" >&2
    echo "Copy VM images into $VM_DIR before launching. See labs/ctrlx-os-virtual/README.md." >&2
    exit 1
  fi
done

qemu-system-x86_64 \
  -display none \
  -enable-kvm \
  -m "$CTRLX_QEMU_MEMORY" \
  -cpu host \
  -smp "$CTRLX_QEMU_CPUS" \
  -kernel "$VM_DIR/kernel.img" \
  -initrd "$VM_DIR/initrd.img" \
  -drive "file=$VM_DIR/virtual-control.base.qcow2,if=virtio" \
  -net nic,model=virtio \
  -net "user,hostfwd=tcp::$CTRLX_SSH_PORT-:22,hostfwd=tcp::$CTRLX_WEB_PORT-:443,hostfwd=tcp::$CTRLX_DATALAYER_PORT-:11740,hostfwd=tcp::$CTRLX_OPCUA_PORT-:4840,hostfwd=tcp::2069-:2069,hostfwd=tcp::2070-:2070,hostfwd=udp::8123-:123" \
  -serial "file:$LOG_FILE" \
  -append "earlycon clk_ignore_unused rng_core.default_quality=700 panic=-1 systemd.unified_cgroup_hierarchy=0 snapd_recovery_mode=run console=ttyS0 console=tty1 net.ifnames=0 usage=evaluation ctrlx-fpga-virtual.virtual=1 ctrlx-ecm.port1=XF50" \
  >"$QEMU_LOG_FILE" 2>&1 &

qemu_pid="$!"
printf '%s\n' "$qemu_pid" >"$PID_FILE"

echo "Started virtual ctrlX CORE '$CTRLX_VM_NAME' with PID $qemu_pid."
echo "Serial log: $LOG_FILE"
echo "QEMU log: $QEMU_LOG_FILE"
echo "Web UI: https://127.0.0.1:$CTRLX_WEB_PORT"
