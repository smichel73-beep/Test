# Lokales Transkriptions-Setup – Anleitung

Vollständig offline, DSGVO-konform. Keine Daten verlassen dein MacBook.

## Installation (einmalig, ca. 10 Minuten + Download)

```bash
# 1. Repository klonen oder Dateien auf den Mac kopieren
# 2. Installationsskript ausführen:
bash ~/path/to/scripts/install.sh

# 3. Neues Terminal-Fenster öffnen (damit PATH gilt)
```

Das Skript installiert automatisch: Homebrew, ffmpeg, whisper-cpp,
das Modell `ggml-large-v3.bin` (~3 GB) nach `~/whisper-models/`
und richtet `~/bin/` ein.

---

## Täglich benutzen

### Terminal

```bash
# Einzelne Datei
transkribiere ~/Downloads/aufnahme.mp3

# Mehrere Dateien auf einmal
transkribiere ~/Downloads/*.mp3

# Video
transkribiere ~/Desktop/meeting.mp4
```

**Ergebnis:** `~/Transkripte/aufnahme.txt` und `~/Transkripte/aufnahme.srt`

### Finder (Rechtsklick)

1. Audio- oder Videodatei im Finder rechtsklicken
2. **Schnellaktionen → Transkribieren**
3. Fertig – TextEdit öffnet sich automatisch mit dem Ergebnis

> Falls "Transkribieren" nicht erscheint: Systemeinstellungen →
> Datenschutz & Sicherheit → Erweiterungen → Finder-Erweiterungen → aktivieren

---

## Zusammenfassung erstellen (benötigt Ollama)

```bash
# Ollama zuerst starten (einmalig pro Sitzung, im Hintergrund lassen):
ollama serve &

# Dann zusammenfassen:
zusammenfassen ~/Transkripte/aufnahme.txt

# Oder interaktiv – listet alle Transkripte zur Auswahl:
zusammenfassen
```

**Ergebnis:** `~/Transkripte/aufnahme_zusammenfassung.md`

Ollama installieren (falls noch nicht): https://ollama.com/download
Modell laden: `ollama pull qwen2.5:14b`

---

## Setup prüfen

```bash
bash ~/path/to/scripts/test_setup.sh
```

---

## Unterstützte Formate

| Audio          | Video          |
|----------------|----------------|
| MP3, WAV, M4A  | MP4, MOV, QTA  |
| AIFF, OGG, FLAC| MKV, AVI, WebM |
| AAC, WMA       | M4V            |

---

## Wo sind meine Dateien?

| Was                    | Wo                                  |
|------------------------|-------------------------------------|
| Transkripte (.txt)     | `~/Transkripte/`                    |
| Zeitstempel (.srt)     | `~/Transkripte/`                    |
| Zusammenfassungen (.md)| `~/Transkripte/`                    |
| Whisper-Modell         | `~/whisper-models/ggml-large-v3.bin`|
| Skripte                | `~/bin/transkribiere`, `~/bin/zusammenfassen` |
| Quick Action           | `~/Library/Services/Transkribieren.workflow` |

---

## Häufige Fragen

**Wie lange dauert die Transkription?**
Ca. 1:3 bis 1:5 – eine 30-Minuten-Aufnahme dauert 6-10 Minuten.
Mit Apple Silicon (M5) ist es deutlich schneller als auf Intel.

**Kann ich eine andere Sprache verwenden?**
Ja: `SPRACHE=en transkribiere datei.mp3` für Englisch.
Oder das Skript öffnen und `SPRACHE="de"` anpassen.

**Wie aktualisiere ich das Modell?**
Einfach neue Modell-Datei nach `~/whisper-models/` kopieren und
im Skript `MODELL=...` anpassen.

**Was ist der Unterschied zwischen .txt und .srt?**
- `.txt` = reiner Fließtext, ideal zum Lesen und Weiterverarbeiten
- `.srt` = Untertiteldatei mit genauen Zeitangaben, ideal für Videos
