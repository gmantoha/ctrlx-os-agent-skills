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
CTRLX_RUNTIME_DIR="${CTRLX_RUNTIME_DIR:-assets/runtime}"

case "$CTRLX_RUNTIME_DIR" in
  /*) RUNTIME_DIR="$CTRLX_RUNTIME_DIR" ;;
  *) RUNTIME_DIR="$LAB_DIR/$CTRLX_RUNTIME_DIR" ;;
esac

PID_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "No PID file found for virtual ctrlX CORE '$CTRLX_VM_NAME'."
  exit 0
fi

qemu_pid="$(<"$PID_FILE")"
if [[ -z "$qemu_pid" ]] || ! kill -0 "$qemu_pid" 2>/dev/null; then
  echo "No running QEMU process found for PID file $PID_FILE."
  rm -f "$PID_FILE"
  exit 0
fi

kill "$qemu_pid"

for _ in {1..20}; do
  if ! kill -0 "$qemu_pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "Stopped virtual ctrlX CORE '$CTRLX_VM_NAME'."
    exit 0
  fi
  sleep 1
done

echo "QEMU process $qemu_pid did not stop after 20 seconds; sending SIGKILL." >&2
kill -9 "$qemu_pid" 2>/dev/null || true
rm -f "$PID_FILE"
echo "Stopped virtual ctrlX CORE '$CTRLX_VM_NAME'."
