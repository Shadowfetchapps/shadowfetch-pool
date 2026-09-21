#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
mkdir -p "$ROOT/export/linux"
exec "$GODOT" --headless --path "$ROOT" --export-release Linux "$ROOT/export/linux/shadowfetch-pool.x86_64"
