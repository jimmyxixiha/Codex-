#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/Codex 用量.app"
DIST="$ROOT/dist"
ZIP="$DIST/Codex用量.zip"

cd "$ROOT"
./build.sh

rm -rf "$DIST"
mkdir -p "$DIST"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "$ZIP"
