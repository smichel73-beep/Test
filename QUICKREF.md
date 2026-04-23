# Lokale KI – Schnellreferenz
Apple M5 · 24 GB RAM · macOS

## Einmalige Installation
```zsh
chmod +x install_lokale_ki.sh
./install_lokale_ki.sh
```
Anschließend **neues Terminal öffnen**, damit die Aliase aktiv sind.

## Täglicher Betrieb
```zsh
ki-start    # Open WebUI starten + Browser öffnen → http://127.0.0.1:8080
ki-stop     # Open WebUI stoppen
ki-status   # Dienststatus prüfen
ki-modelle  # Alle Modelle auflisten
```

## Modelle im Dropdown
| Modell | Stärke |
|--------|--------|
| `sven-business` | Sachliche Geschäftstexte, kein Floskeln |
| `sven-email` | Fertige E-Mails, endet mit „Sven" |
| `sven-angebot` | Struktur: Lage → Lösung → Nutzen → Schritt |
| `qwen2.5:14b-instruct-q4_K_M` | Bestes Allround-Modell Deutsch/Business |
| `llama3.1:8b-instruct-q5_K_M` | Schnell, für kurze Aufgaben |
| `mistral-nemo:12b` | Reasoning, 128k Kontext |
| `gemma2:9b-instruct-q4_K_M` | Alternative für längere Texte |

## Ressourcenverbrauch (ca.)
| Modell | RAM | Platz |
|--------|-----|-------|
| llama3.1:8b-q5 | ~6 GB | 5,7 GB |
| gemma2:9b-q4 | ~6 GB | 5,8 GB |
| mistral-nemo:12b | ~8 GB | 7,1 GB |
| qwen2.5:14b-q4 | ~10 GB | 9,0 GB |
| **Gesamt** | | **~28 GB** |

## Modelfile anpassen
```zsh
# Datei bearbeiten
nano ~/Documents/LokaleKI/modelfiles/sven-business.modelfile

# Modell neu erstellen
ollama create sven-business -f ~/Documents/LokaleKI/modelfiles/sven-business.modelfile
```
