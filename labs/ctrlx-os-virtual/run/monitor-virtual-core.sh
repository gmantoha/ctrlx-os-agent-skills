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

LOG_FILE="$RUNTIME_DIR/$CTRLX_VM_NAME.serial.log"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Serial log does not exist yet: $LOG_FILE" >&2
  exit 1
fi

tail -f "$LOG_FILE"
