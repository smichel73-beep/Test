#!/bin/zsh
# Lokale KI Setup – Apple M5 / 24 GB RAM
# Sven Michel / michel-gmbh

set -e

VENV_DIR="$HOME/.venvs/open-webui"
MODELFILES_DIR="$HOME/Documents/LokaleKI/modelfiles"
DOCS_DIR="$HOME/Documents/LokaleKI"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo "${GREEN}[OK]${NC} $1"; }
step()  { echo "\n${YELLOW}>>> $1${NC}"; }

# ──────────────────────────────────────────────
step "1 / 7  Ollama installieren"
# ──────────────────────────────────────────────
if command -v ollama &>/dev/null; then
  info "Ollama bereits vorhanden – wird übersprungen"
else
  brew install ollama
  info "Ollama installiert"
fi

# Dienst aktivieren (läuft künftig automatisch beim Login)
brew services start ollama 2>/dev/null || true
info "Ollama-Dienst gestartet"

# kurz warten bis API erreichbar ist
for i in {1..15}; do
  curl -s http://127.0.0.1:11434 &>/dev/null && break
  sleep 2
done

# ──────────────────────────────────────────────
step "2 / 7  Modelle laden"
# ──────────────────────────────────────────────
# Reihenfolge: kleinstes zuerst, damit du schnell starten kannst
MODELS=(
  "llama3.1:8b-instruct-q5_K_M"
  "gemma2:9b-instruct-q4_K_M"
  "mistral-nemo:12b"
  "qwen2.5:14b-instruct-q4_K_M"
)

for m in "${MODELS[@]}"; do
  echo "  -> $m"
  ollama pull "$m"
done
info "Alle Basis-Modelle geladen"

# ──────────────────────────────────────────────
step "3 / 7  Modelfiles & Custom-Modelle"
# ──────────────────────────────────────────────
mkdir -p "$MODELFILES_DIR"

cat > "$MODELFILES_DIR/sven-business.modelfile" <<'MEOF'
FROM qwen2.5:14b-instruct-q4_K_M

PARAMETER temperature 0.3
PARAMETER num_ctx 8192

SYSTEM """
Du bist ein sachlicher Geschäftsassistent für Sven Michel.
Antworte präzise, ohne Floskeln wie "gerne", "selbstverständlich" oder "natürlich".
Verwende klares Deutsch, Bulletpoints wo sinnvoll, kurze Absätze.
Kein unnötiger Smalltalk. Kein Marketing-Sprech.
"""
MEOF

cat > "$MODELFILES_DIR/sven-email.modelfile" <<'MEOF'
FROM llama3.1:8b-instruct-q5_K_M

PARAMETER temperature 0.4
PARAMETER num_ctx 4096

SYSTEM """
Du schreibst fertige E-Mails für Sven Michel.
Liefere immer sofort den vollständigen E-Mail-Text – keine Erklärungen davor oder danach.
Beende die E-Mail immer mit: Sven
Kein "Beste Grüße", kein "Mit freundlichen Grüßen" außer wenn explizit verlangt.
Kein Kommentar über deine eigene Antwort.
"""
MEOF

cat > "$MODELFILES_DIR/sven-angebot.modelfile" <<'MEOF'
FROM qwen2.5:14b-instruct-q4_K_M

PARAMETER temperature 0.35
PARAMETER num_ctx 8192

SYSTEM """
Du erstellst Angebotstexte für Sven Michel nach folgender Struktur:
1. Ausgangslage – Was ist die Situation / das Problem des Kunden?
2. Lösung – Was bietet michel-gmbh konkret an?
3. Nutzen – Welchen messbaren Vorteil hat der Kunde?
4. Nächster Schritt – Eine klare Handlungsaufforderung.
Kurze Absätze. Kein Fülltext. Kein Floskeln.
"""
MEOF

ollama create sven-business -f "$MODELFILES_DIR/sven-business.modelfile"
ollama create sven-email    -f "$MODELFILES_DIR/sven-email.modelfile"
ollama create sven-angebot  -f "$MODELFILES_DIR/sven-angebot.modelfile"
info "Custom-Modelle erstellt"

# ──────────────────────────────────────────────
step "4 / 7  Open WebUI installieren"
# ──────────────────────────────────────────────
# Python 3.11 bevorzugt (breite Kompatibilität mit Open WebUI)
PYTHON=$(command -v python3.11 || command -v python3 || echo "")
if [ -z "$PYTHON" ]; then
  brew install python@3.11
  PYTHON=$(brew --prefix)/bin/python3.11
fi

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON" -m venv "$VENV_DIR"
  info "venv erstellt: $VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip --quiet
pip install open-webui --quiet
deactivate
info "Open WebUI installiert"

# ──────────────────────────────────────────────
step "5 / 7  Aliase in ~/.zprofile eintragen"
# ──────────────────────────────────────────────
ZPROFILE="$HOME/.zprofile"

add_alias() {
  local name=$1 cmd=$2
  if grep -q "alias $name=" "$ZPROFILE" 2>/dev/null; then
    # vorhandenen Eintrag aktualisieren
    sed -i '' "s|alias $name=.*|alias $name='$cmd'|" "$ZPROFILE"
  else
    echo "alias $name='$cmd'" >> "$ZPROFILE"
  fi
}

# Trennblock nur einmal einfügen
grep -q "# Lokale KI" "$ZPROFILE" 2>/dev/null || \
  echo "\n# Lokale KI" >> "$ZPROFILE"

add_alias ki-start  "pgrep -f 'open-webui serve' &>/dev/null || ($VENV_DIR/bin/open-webui serve >>/tmp/open-webui.log 2>&1 &); for i in {1..30}; do curl -s http://127.0.0.1:8080 &>/dev/null && break; sleep 2; done; open http://127.0.0.1:8080"
add_alias ki-stop   "pkill -f 'open-webui serve' 2>/dev/null; echo 'Open WebUI gestoppt'"
add_alias ki-status "echo '=== Ollama ==='; curl -s http://127.0.0.1:11434 && echo OK || echo NICHT ERREICHBAR; echo '=== Open WebUI ==='; pgrep -f 'open-webui serve' &>/dev/null && echo 'LÄUFT' || echo 'GESTOPPT'"
add_alias ki-modelle "ollama list"

info "Aliase eingetragen"

# ──────────────────────────────────────────────
step "6 / 7  Desktop-App erstellen"
# ──────────────────────────────────────────────
APP_PATH="$HOME/Desktop/Lokale KI.app"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"

# Vollständiger Pfad zum venv-Binary – kein source/activate nötig,
# funktioniert auch wenn Finder die App ohne Login-Shell startet.
cat > "$APP_PATH/Contents/MacOS/start" <<APPEOF
#!/bin/zsh
# Nichts tun wenn Open WebUI bereits läuft
pgrep -f "open-webui serve" &>/dev/null || \
  "$VENV_DIR/bin/open-webui" serve >>/tmp/open-webui.log 2>&1 &

# Warten bis Server antwortet (max. 60 Sek.)
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

# macOS-Quarantäne-Flag entfernen (verhindert "beschädigte App"-Warnung)
xattr -cr "$APP_PATH" 2>/dev/null || true

info "Desktop-App erstellt: $APP_PATH"

# ──────────────────────────────────────────────
step "7 / 7  Dokumentation schreiben"
# ──────────────────────────────────────────────
mkdir -p "$DOCS_DIR"

cat > "$DOCS_DIR/README.md" <<'DOCEOF'
# Lokale KI – Bedienungsanleitung
Sven Michel / michel-gmbh

## Schnellstart
1. Terminal öffnen → `ki-start`
   Oder: Doppelklick auf **Lokale KI.app** (Schreibtisch)
2. Browser öffnet **http://127.0.0.1:8080**
3. Modell im Dropdown wählen

## Aliase
| Alias | Funktion |
|-------|----------|
| `ki-start`   | Open WebUI starten + Browser öffnen |
| `ki-stop`    | Open WebUI stoppen |
| `ki-status`  | Dienststatus anzeigen |
| `ki-modelle` | Alle Modelle auflisten |

## Modelle
| Modell | Basis | Einsatz |
|--------|-------|---------|
| `sven-business` | qwen2.5:14b | Sachliche Geschäftskommunikation |
| `sven-email`    | llama3.1:8b | Fertige E-Mails |
| `sven-angebot`  | qwen2.5:14b | Angebotstexte (Lage→Lösung→Nutzen→Schritt) |
| `qwen2.5:14b`   | –           | Allgemein Deutsch/Business |
| `llama3.1:8b`   | –           | Schnell, Allround |
| `mistral-nemo`  | –           | Reasoning, 128k Kontext |
| `gemma2:9b`     | –           | Längere Texte |

## Dienste
- Ollama API: http://127.0.0.1:11434
- Open WebUI: http://127.0.0.1:8080
- Modelle:    ~/.ollama/models/

## Modelfiles anpassen
Die Modelfiles liegen unter:
`~/Documents/LokaleKI/modelfiles/`

Nach Änderungen neu erstellen:
```
ollama create sven-business -f ~/Documents/LokaleKI/modelfiles/sven-business.modelfile
```

## Ollama-Dienst
Ollama läuft als Hintergrunddienst (startet automatisch):
```
brew services start ollama   # starten
brew services stop ollama    # stoppen
brew services list           # Status
```
DOCEOF

info "Dokumentation: $DOCS_DIR/README.md"

# ──────────────────────────────────────────────
echo "\n${GREEN}════════════════════════════════════════${NC}"
echo "${GREEN}  Setup abgeschlossen!${NC}"
echo "${GREEN}════════════════════════════════════════${NC}"
echo "Starte die KI jetzt mit:  ki-start"
echo "(Einmal neues Terminal öffnen, damit Aliase aktiv sind)"
