#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

CTRLX_WEB_URL="${CTRLX_WEB_URL:-https://127.0.0.1:8443}"
CTRLX_WAIT_TIMEOUT="${CTRLX_WAIT_TIMEOUT:-180}"

deadline=$((SECONDS + CTRLX_WAIT_TIMEOUT))

echo "Waiting up to ${CTRLX_WAIT_TIMEOUT}s for $CTRLX_WEB_URL ..."

while (( SECONDS < deadline )); do
  if curl --insecure --silent --show-error --max-time 5 --output /dev/null "$CTRLX_WEB_URL"; then
    echo "Virtual ctrlX CORE is reachable at $CTRLX_WEB_URL."
    exit 0
  fi
  sleep 5
done

echo "Timed out waiting for virtual ctrlX CORE at $CTRLX_WEB_URL." >&2
exit 1
