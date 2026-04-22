#!/usr/bin/env bash
# ============================================================
# Installationsskript für das lokale Transkriptions-Setup
# Ausführen mit: bash install.sh
# ============================================================

set -e

WHISPER_MODEL_DIR="$HOME/whisper-models"
TRANSKRIPTE_DIR="$HOME/Transkripte"
BIN_DIR="$HOME/bin"
ZSHRC="$HOME/.zshrc"

echo "======================================"
echo "  Lokales Transkriptions-Setup"
echo "======================================"
echo ""

# --- 1. Homebrew ---
if ! command -v brew &>/dev/null; then
    echo "→ Installiere Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Homebrew PATH für Apple Silicon einrichten
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✓ Homebrew ist bereits installiert ($(brew --version | head -1))"
fi

# --- 2. ffmpeg ---
if ! command -v ffmpeg &>/dev/null; then
    echo "→ Installiere ffmpeg..."
    brew install ffmpeg
else
    echo "✓ ffmpeg ist bereits installiert ($(ffmpeg -version 2>&1 | head -1 | awk '{print $3}'))"
fi

# --- 3. whisper-cpp ---
if ! command -v whisper-cpp &>/dev/null && ! command -v whisper &>/dev/null; then
    echo "→ Installiere whisper-cpp..."
    brew install whisper-cpp
else
    WHISPER_CMD=$(command -v whisper-cpp 2>/dev/null || command -v whisper 2>/dev/null)
    echo "✓ whisper-cpp ist bereits installiert ($WHISPER_CMD)"
fi

# --- 4. Modell-Verzeichnis anlegen ---
if [ ! -d "$WHISPER_MODEL_DIR" ]; then
    echo "→ Erstelle Verzeichnis $WHISPER_MODEL_DIR ..."
    mkdir -p "$WHISPER_MODEL_DIR"
else
    echo "✓ Modell-Verzeichnis existiert bereits: $WHISPER_MODEL_DIR"
fi

# --- 5. Whisper-Modell large-v3 herunterladen ---
MODEL_FILE="$WHISPER_MODEL_DIR/ggml-large-v3.bin"
if [ ! -f "$MODEL_FILE" ]; then
    echo "→ Lade Whisper-Modell large-v3 herunter (ca. 3 GB, bitte warten)..."
    curl -L \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin" \
        -o "$MODEL_FILE" \
        --progress-bar
    echo "✓ Modell gespeichert: $MODEL_FILE"
else
    echo "✓ Modell bereits vorhanden: $MODEL_FILE"
fi

# --- 6. Transkripte-Verzeichnis ---
if [ ! -d "$TRANSKRIPTE_DIR" ]; then
    echo "→ Erstelle Verzeichnis $TRANSKRIPTE_DIR ..."
    mkdir -p "$TRANSKRIPTE_DIR"
else
    echo "✓ Transkripte-Verzeichnis existiert bereits: $TRANSKRIPTE_DIR"
fi

# --- 7. ~/bin anlegen ---
if [ ! -d "$BIN_DIR" ]; then
    echo "→ Erstelle Verzeichnis $BIN_DIR ..."
    mkdir -p "$BIN_DIR"
else
    echo "✓ ~/bin existiert bereits"
fi

# --- 8. Skripte installieren ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Installiere Skript 'transkribiere'..."
cp "$SCRIPT_DIR/transkribiere" "$BIN_DIR/transkribiere"
chmod +x "$BIN_DIR/transkribiere"
echo "✓ transkribiere installiert: $BIN_DIR/transkribiere"

echo "→ Installiere Skript 'zusammenfassen'..."
cp "$SCRIPT_DIR/zusammenfassen" "$BIN_DIR/zusammenfassen"
chmod +x "$BIN_DIR/zusammenfassen"
echo "✓ zusammenfassen installiert: $BIN_DIR/zusammenfassen"

# --- 9. ~/bin zum PATH in ~/.zshrc hinzufügen ---
PATH_EINTRAG='export PATH="$HOME/bin:$PATH"'
if ! grep -qF 'HOME/bin' "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# Eigene Skripte" >> "$ZSHRC"
    echo "$PATH_EINTRAG" >> "$ZSHRC"
    echo "✓ ~/bin zum PATH in ~/.zshrc hinzugefügt"
else
    echo "✓ ~/bin ist bereits in ~/.zshrc eingetragen"
fi

# --- 10. Quick Action installieren (Finder-Integration) ---
QUICK_ACTION_SRC="$SCRIPT_DIR/../automator/Transkribieren.workflow"
QUICK_ACTION_DST="$HOME/Library/Services/Transkribieren.workflow"

if [ -d "$QUICK_ACTION_SRC" ]; then
    if [ ! -d "$QUICK_ACTION_DST" ]; then
        echo "→ Installiere Finder Quick Action..."
        cp -R "$QUICK_ACTION_SRC" "$QUICK_ACTION_DST"
        echo "✓ Quick Action installiert: $QUICK_ACTION_DST"
    else
        echo "✓ Quick Action bereits installiert"
    fi
fi

echo ""
echo "======================================"
echo "  Installation abgeschlossen!"
echo "======================================"
echo ""
echo "Starte ein neues Terminal-Fenster, dann kannst du sofort loslegen:"
echo "  transkribiere ~/Downloads/meine_aufnahme.mp3"
echo ""
echo "Finder-Integration: Rechtsklick auf Audio/Video → Schnellaktionen → Transkribieren"
echo ""
