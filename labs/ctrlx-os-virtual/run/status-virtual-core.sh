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
CTRLX_WEB_URL="${CTRLX_WEB_URL:-https://127.0.0.1:8443}"
CTRLX_SSH_HOST="${CTRLX_SSH_HOST:-127.0.0.1}"
CTRLX_SSH_PORT="${CTRLX_SSH_PORT:-8022}"
CTRLX_WEB_PORT="${CTRLX_WEB_PORT:-8443}"
CTRLX_DATALAYER_PORT="${CTRLX_DATALAYER_PORT:-8740}"
CTRLX_OPCUA_PORT="${CTRLX_OPCUA_PORT:-4840}"

case "$CTRLX_RUNTIME_DIR" in
  /*) RUNTIME_DIR="$CTRLX_RUNTIME_DIR" ;;
  *) RUNTIME_DIR="$LAB_DIR/$CTRLX_RUNTIME_DIR" ;;
esac

PID_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.pid"
LOG_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.serial.log"
QEMU_LOG_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.qemu.log"

echo "Virtual ctrlX CORE: $CTRLX_VM_NAME"

if [[ -f "$PID_FILE" ]]; then
  qemu_pid="$(<"$PID_FILE")"
  if [[ -n "$qemu_pid" ]] && kill -0 "$qemu_pid" 2>/dev/null; then
    echo "Process: running (PID $qemu_pid)"
  else
    echo "Process: stale PID file ($PID_FILE)"
  fi
else
  echo "Process: not running (no PID file)"
fi

for port in "$CTRLX_SSH_PORT" "$CTRLX_WEB_PORT" "$CTRLX_DATALAYER_PORT" "$CTRLX_OPCUA_PORT"; do
  if timeout 1 bash -c "</dev/tcp/$CTRLX_SSH_HOST/$port" 2>/dev/null; then
    echo "Port $port: open"
  else
    echo "Port $port: closed"
  fi
done

if curl --insecure --silent --show-error --max-time 5 --output /dev/null "$CTRLX_WEB_URL"; then
  echo "Web UI: reachable ($CTRLX_WEB_URL)"
else
  echo "Web UI: not reachable yet ($CTRLX_WEB_URL)"
fi

echo "Serial log: $LOG_FILE"
echo "QEMU log: $QEMU_LOG_FILE"
