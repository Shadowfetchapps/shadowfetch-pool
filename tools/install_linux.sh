#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME}"
ICON_SRC="$ROOT/icon.svg"
HICOLOR="$HOME_DIR/.local/share/icons/hicolor"
APP_DIR="$HOME_DIR/.local/share/applications"
BIN_DIR="$HOME_DIR/.local/bin"
SIZES=(16 22 24 32 48 64 128 256 512)
mkdir -p "$HICOLOR/scalable/apps" "$APP_DIR" "$BIN_DIR" "$ROOT/assets/icons/hicolor/scalable/apps"
cp "$ICON_SRC" "$HICOLOR/scalable/apps/shadowfetch-pool.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/shadowfetch-pool.svg"
cp "$ICON_SRC" "$ROOT/assets/icons/hicolor/scalable/apps/shadowfetch-pool.svg"
for sz in "${SIZES[@]}"; do
	mkdir -p "$HICOLOR/${sz}x${sz}/apps" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps"
	rsvg-convert -w "$sz" -h "$sz" "$ICON_SRC" -o "$HICOLOR/${sz}x${sz}/apps/shadowfetch-pool.png"
	cp "$HICOLOR/${sz}x${sz}/apps/shadowfetch-pool.png" "$ROOT/assets/icons/hicolor/${sz}x${sz}/apps/shadowfetch-pool.png"
done
cat > "$BIN_DIR/shadowfetch-pool" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\${SHADOWFETCH_POOL_ROOT:-$ROOT}"
BIN="\$ROOT/export/linux/shadowfetch-pool.x86_64"
if [[ -x "\$BIN" ]]; then
	exec "\$BIN" "\$@"
fi
echo "Shadowfetch Pool: exported Linux build not found. Run tools/export_linux.sh" >&2
exit 1
EOF
chmod +x "$BIN_DIR/shadowfetch-pool"
cat > "$APP_DIR/shadowfetch-pool.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Shadowfetch Pool
GenericName=Pool
Comment=8-Ball and 9-Ball for Linux
Exec=$BIN_DIR/shadowfetch-pool
TryExec=$BIN_DIR/shadowfetch-pool
Icon=shadowfetch-pool
Terminal=false
Categories=Game;
Keywords=pool;billiards;8-ball;9-ball;shadowfetch;
StartupNotify=true
StartupWMClass=Shadowfetch Pool
EOF
desktop-file-validate "$APP_DIR/shadowfetch-pool.desktop"
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "Installed Shadowfetch Pool launcher: $BIN_DIR/shadowfetch-pool"
