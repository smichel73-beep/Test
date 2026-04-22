#!/usr/bin/env bash
# ============================================================
# test_setup.sh – Prüft ob das Transkriptions-Setup korrekt
# installiert ist, und testet mit der Sedus-MP3 falls vorhanden
# ============================================================

set -euo pipefail

FEHLER=0
OK=0

echo "======================================"
echo "  Setup-Test Lokale Transkription"
echo "======================================"
echo ""

# Hilfsfunktion: Prüfung ausgeben
pruefe() {
    local beschreibung="$1"
    local bedingung="$2"
    if eval "$bedingung" &>/dev/null; then
        echo "✓ $beschreibung"
        OK=$((OK + 1))
    else
        echo "✗ $beschreibung"
        FEHLER=$((FEHLER + 1))
    fi
}

# ---- Abhängigkeiten prüfen --------------------------------
echo "Abhängigkeiten:"
pruefe "Homebrew installiert" "command -v brew"
pruefe "ffmpeg installiert" "command -v ffmpeg"
pruefe "whisper-cpp installiert" "command -v whisper-cpp || command -v whisper"
pruefe "~/bin vorhanden" "[ -d '$HOME/bin' ]"
pruefe "~/whisper-models vorhanden" "[ -d '$HOME/whisper-models' ]"
pruefe "~/Transkripte vorhanden" "[ -d '$HOME/Transkripte' ]"
pruefe "Modell large-v3 vorhanden (3 GB)" "[ -f '$HOME/whisper-models/ggml-large-v3.bin' ]"
pruefe "transkribiere-Skript installiert" "[ -x '$HOME/bin/transkribiere' ]"
pruefe "zusammenfassen-Skript installiert" "[ -x '$HOME/bin/zusammenfassen' ]"
pruefe "~/bin im PATH" "echo \$PATH | grep -q '$HOME/bin'"

echo ""
echo "Optional:"
pruefe "Quick Action installiert" "[ -d '$HOME/Library/Services/Transkribieren.workflow' ]"
pruefe "Ollama läuft" "curl -s http://localhost:11434/api/generate"

# ---- Test mit Sedus-Datei ---------------------------------
TESTDATEI="$HOME/Downloads/Sedus_Hub_Berlin_Treffpunkt_Buero.mp3"
echo ""
echo "--------------------------------------"

if [ ! -f "$TESTDATEI" ]; then
    echo "Test-MP3 nicht gefunden: $TESTDATEI"
    echo "Test wird übersprungen."
    echo "Zum manuellen Testen:"
    echo "  transkribiere ~/Downloads/Sedus_Hub_Berlin_Treffpunkt_Buero.mp3"
else
    echo "Test-Datei gefunden: $(basename "$TESTDATEI")"
    GROESSE=$(du -h "$TESTDATEI" | cut -f1)
    echo "Dateigröße: $GROESSE"

    if [ "$FEHLER" -gt 0 ]; then
        echo ""
        echo "WARNUNG: $FEHLER Abhängigkeit(en) fehlen – Test wird nicht durchgeführt."
        echo "Bitte install.sh zuerst ausführen."
    else
        echo ""
        echo "Starte Transkription..."
        echo "(Das kann je nach Dateilänge einige Minuten dauern)"
        echo ""

        if transkribiere "$TESTDATEI"; then
            echo ""
            echo "TEST ERFOLGREICH!"
            TXT_DATEI="$HOME/Transkripte/Sedus_Hub_Berlin_Treffpunkt_Buero.txt"
            if [ -f "$TXT_DATEI" ]; then
                WORTANZAHL=$(wc -w < "$TXT_DATEI")
                echo "Ergebnis: $WORTANZAHL Wörter transkribiert"
            fi
        else
            echo "TEST FEHLGESCHLAGEN – Details oben lesen"
            FEHLER=$((FEHLER + 1))
        fi
    fi
fi

# ---- Zusammenfassung --------------------------------------
echo ""
echo "======================================"
if [ "$FEHLER" -eq 0 ]; then
    echo "  Alles in Ordnung! ($OK Checks bestanden)"
else
    echo "  $FEHLER Problem(e) gefunden, $OK OK"
    echo "  Bitte install.sh ausführen:"
    echo "  bash ~/bin/../setup/install.sh"
fi
echo "======================================"
