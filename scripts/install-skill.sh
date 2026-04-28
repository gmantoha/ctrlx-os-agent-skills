#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

agent="${CTRLX_SKILL_AGENT:-opencode}"
scope="${CTRLX_SKILL_SCOPE:-global}"
scope_args=()

case "$scope" in
  global|--global|-g)
    scope_args=(--global)
    ;;
  project|local|--project|-p)
    scope_args=()
    ;;
  *)
    echo "Unsupported CTRLX_SKILL_SCOPE: $scope" >&2
    echo "Use 'global' or 'project'." >&2
    exit 2
    ;;
esac

npx skills add "$repo_root" \
  --skill ctrlx \
  --agent "$agent" \
  "${scope_args[@]}" \
  --copy \
  --yes
