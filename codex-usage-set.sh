#!/usr/bin/env bash
set -euo pipefail

PERCENT="${1:-72}"
RESET_LABEL="${2:-明日 08:00 重置}"
PLAN="${3:-Codex}"
TARGET="${HOME}/Library/Application Support/CodexUsageWidget/usage.json"

mkdir -p "$(dirname "$TARGET")"

if ! [[ "$PERCENT" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <0-100> [reset-label] [plan]" >&2
  exit 2
fi

if (( PERCENT < 0 )); then PERCENT=0; fi
if (( PERCENT > 100 )); then PERCENT=100; fi

USED=$((100 - PERCENT))
UPDATED="$(date '+%H:%M')"

cat > "$TARGET" <<JSON
{
  "plan": "$PLAN",
  "title": "剩余用量",
  "remainingPercent": $PERCENT,
  "remainingLabel": "$PERCENT%",
  "usedLabel": "已用 $USED%",
  "resetLabel": "$RESET_LABEL",
  "status": "本地更新",
  "updatedAt": "$UPDATED",
  "samples": [
    { "label": "当前", "value": "$PERCENT%", "detail": "可用" },
    { "label": "已用", "value": "$USED%", "detail": "估计" },
    { "label": "更新", "value": "$UPDATED", "detail": "本机" },
    { "label": "重置", "value": "${RESET_LABEL%% *}", "detail": "${RESET_LABEL#* }" }
  ]
}
JSON

echo "$TARGET"
