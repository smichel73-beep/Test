#!/bin/zsh
# Repariert nur das Desktop-Icon (Lokale KI.app)
# Für alle, die install_lokale_ki.sh bereits ausgeführt haben.

VENV_DIR="$HOME/.venvs/open-webui"
APP_PATH="$HOME/Desktop/Lokale KI.app"

if [ ! -f "$VENV_DIR/bin/open-webui" ]; then
  echo "FEHLER: open-webui nicht gefunden unter $VENV_DIR/bin/open-webui"
  echo "Bitte install_lokale_ki.sh vollständig ausführen."
  exit 1
fi

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"

cat > "$APP_PATH/Contents/MacOS/start" <<APPEOF
#!/bin/zsh
pgrep -f "open-webui serve" &>/dev/null || \
  "$VENV_DIR/bin/open-webui" serve >>/tmp/open-webui.log 2>&1 &

for i in {1..30}; do
  curl -s http://127.0.0.1:8080 &>/dev/null && break
  sleep 2
done
open http://127.0.0.1:8080
APPEOF
chmod +x "$APP_PATH/Contents/MacOS/start"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>   <string>start</string>
  <key>CFBundleName</key>         <string>Lokale KI</string>
  <key>CFBundlePackageType</key>  <string>APPL</string>
  <key>CFBundleIdentifier</key>   <string>de.michel-gmbh.lokale-ki</string>
  <key>CFBundleVersion</key>      <string>1.0</string>
</dict>
</plist>
PLIST

xattr -cr "$APP_PATH" 2>/dev/null || true

echo "Desktop-Icon repariert: $APP_PATH"
echo "Doppelklick auf 'Lokale KI' auf dem Schreibtisch zum Starten."
