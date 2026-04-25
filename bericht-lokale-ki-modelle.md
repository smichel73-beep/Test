# Bericht: Lokal installierte KI-Modelle

**Datum:** 25. April 2026  
**System:** Linux (Kernel 4.4.0), x86_64, 16 CPU-Kerne, 21 GiB RAM  
**Arbeitsverzeichnis:** `/home/user/Test`

---

## Zusammenfassung

Eine vollständige Untersuchung des Systems ergab **keine lokal installierten KI-Modelle**. Es wurden weder Modell-Gewichtsdateien noch entsprechende Laufzeitumgebungen oder Dienste gefunden.

---

## Untersuchungsumfang

Folgende Komponenten wurden systematisch geprüft:

### 1. KI-Laufzeitumgebungen (CLI-Tools)

| Tool | Status |
|------|--------|
| `ollama` | Nicht installiert |
| `llama.cpp` | Nicht installiert |
| `llama` / `llama-cli` | Nicht installiert |
| `lm-studio` | Nicht installiert |
| `koboldcpp` | Nicht installiert |
| `llamafile` | Nicht installiert |
| `vllm` | Nicht installiert |
| `localai` | Nicht installiert |
| `gpt4all` | Nicht installiert |

### 2. Modell-Gewichtsdateien

Folgende Dateiformate wurden systemweit gesucht:

| Format | Beschreibung | Gefunden |
|--------|-------------|---------|
| `.gguf` | GGUF-Format (llama.cpp) | Nein |
| `.ggml` | GGML-Format (veraltet) | Nein |
| `.safetensors` | HuggingFace SafeTensors | Nein |
| `.bin` (ML) | PyTorch / Transformers Gewichte | Nein |
| `Modelfile` | Ollama Modelfile | Nein |

### 3. Python-Bibliotheken (ML/KI)

| Paket | Status |
|-------|--------|
| `torch` / `pytorch` | Nicht installiert |
| `transformers` (HuggingFace) | Nicht installiert |
| `llama-cpp-python` | Nicht installiert |
| `ctransformers` | Nicht installiert |
| `ollama` (Python-Client) | Nicht installiert |
| `langchain` | Nicht installiert |
| `openai` | Nicht installiert |
| `anthropic` | Nicht installiert |
| `vllm` | Nicht installiert |
| `diffusers` | Nicht installiert |

### 4. Systemdienste & Prozesse

- Keine laufenden KI-bezogenen Prozesse (`ps aux`)
- Keine systemd-Dienste für KI-Tools (`/etc/systemd/system/`)
- Keine Init-Skripte für KI-Tools (`/etc/init.d/`)

### 5. Hardware

| Komponente | Status |
|-----------|--------|
| NVIDIA GPU | Nicht vorhanden (`nvidia-smi` nicht verfügbar) |
| AMD GPU (ROCm) | Nicht vorhanden (`rocm-smi` nicht verfügbar) |
| CPU | 16 Kerne, x86_64 (Modell: unbekannt) |
| RAM | 21 GiB (davon ~20 GiB verfügbar) |

### 6. Modell-Verzeichnisse

Folgende Standardpfade wurden geprüft:

| Pfad | Status |
|------|--------|
| `~/.ollama/models/` | Existiert nicht |
| `/usr/share/ollama/` | Existiert nicht |
| Beliebige `models/`-Verzeichnisse unter `/home`, `/opt`, `/usr/local` | Nicht gefunden |

---

## Ergebnis

**Es sind keine lokal installierten KI-Modelle auf diesem System vorhanden.**

Das System enthält keine:
- Modell-Gewichtsdateien (GGUF, SafeTensors, etc.)
- KI-Inferenz-Engines (Ollama, llama.cpp, etc.)
- ML-Python-Bibliotheken
- GPU-Hardware zur Beschleunigung

---

## Empfehlungen für lokale KI-Modell-Installation

Falls lokal KI-Modelle betrieben werden sollen, sind folgende Optionen gängig:

### Option A: Ollama (einfachste Methode)

```bash
# Installation
curl -fsSL https://ollama.com/install.sh | sh

# Modell herunterladen und starten
ollama run llama3.2

# API ansprechen (OpenAI-kompatibel)
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [{"role": "user", "content": "Hallo!"}]
}'

# Systemprompt setzen
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "system", "content": "Du bist ein hilfreicher Assistent."},
    {"role": "user", "content": "Hallo!"}
  ]
}'
```

**Beliebte Ollama-Modelle:**

| Modell | Größe | Anwendungsfall |
|--------|-------|----------------|
| `llama3.2:3b` | ~2 GB | Schnell, geringer VRAM |
| `llama3.2:latest` (8B) | ~5 GB | Allgemein |
| `mistral:7b` | ~4 GB | Allgemein, gut auf Deutsch |
| `deepseek-coder-v2` | ~9 GB | Code |
| `gemma3:12b` | ~8 GB | Multimodal |
| `phi4:14b` | ~9 GB | Reasoning |
| `qwen2.5:7b` | ~5 GB | Mehrsprachig, Deutsch |

### Option B: llama.cpp (direkt, maximale Kontrolle)

```bash
# Kompilieren
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && make -j

# Modell laden und Server starten
./llama-server -m /pfad/zu/modell.gguf --port 8080

# API ansprechen
curl http://localhost:8080/v1/chat/completions -d '{
  "messages": [
    {"role": "system", "content": "Dein Systemprompt hier."},
    {"role": "user", "content": "Hallo!"}
  ]
}'
```

### Option C: LM Studio (grafische Oberfläche)

Verfügbar unter https://lmstudio.ai – bietet eine GUI zur Verwaltung und Nutzung von GGUF-Modellen. Stellt ebenfalls einen lokalen OpenAI-kompatiblen API-Server bereit.

---

## Systemprompt-Konzept

Bei lokalen Modellen wird der Systemprompt üblicherweise als erster Eintrag im `messages`-Array mit `"role": "system"` übergeben:

```json
{
  "model": "llama3.2",
  "messages": [
    {
      "role": "system",
      "content": "Du bist ein spezialisierter Assistent für [Aufgabe]. Antworte immer auf Deutsch. Sei präzise und knapp."
    },
    {
      "role": "user",
      "content": "Nutzerfrage hier"
    }
  ]
}
```

Bei Ollama kann ein dauerhafter Systemprompt auch über ein `Modelfile` definiert werden:

```Dockerfile
FROM llama3.2
SYSTEM "Du bist ein hilfreicher Assistent. Antworte immer auf Deutsch."
```

```bash
ollama create mein-assistent -f Modelfile
ollama run mein-assistent
```
