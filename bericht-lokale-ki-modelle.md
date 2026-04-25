# Bericht: Lokal installierte KI-Modelle

**Datum:** 25. April 2026  
**Nutzer:** Sven  
**Frontend:** Open WebUI (Ollama-Backend)

---

## Zusammenfassung

Auf dem lokalen System sind **3 KI-Modelle** über Ollama und Open WebUI verfügbar. Der erste Scan der Serverumgebung ergab keine Modelle, da Ollama auf dem Host-Rechner (macOS) läuft – nicht im Container. Die Modelle wurden über den Screenshot der Open WebUI identifiziert.

---

## Installierte Modelle

### 1. `sven-llama3.1:8b-instruct-q5_K_M` *(aktiv ausgewählt)*

| Eigenschaft | Wert |
|-------------|------|
| Basis-Modell | Meta Llama 3.1 8B Instruct |
| Quantisierung | Q5_K_M (~5 GB VRAM) |
| Typ | **Custom Model** (via Ollama Modelfile) |
| Erstellt von | Sven (persönliche Konfiguration) |
| Quelle | Lokal angepasst mit `ollama create` |

**Erklärung:** Das Präfix `sven-` zeigt, dass dieses Modell über ein Ollama `Modelfile` erstellt wurde – typischerweise um einen **eigenen Systemprompt** dauerhaft einzubetten. Es basiert auf `llama3.1:8b-instruct-q5_K_M`, wurde aber mit individueller Konfiguration (Name, Systemprompt, ggf. Parameter) versehen.

**API-Aufruf:**
```bash
# Ollama native API
curl http://localhost:11434/api/chat -d '{
  "model": "sven-llama3.1:8b-instruct-q5_K_M",
  "messages": [{"role": "user", "content": "Hallo!"}]
}'

# OpenAI-kompatibler Endpunkt (Open WebUI / Ollama)
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sven-llama3.1:8b-instruct-q5_K_M",
    "messages": [{"role": "user", "content": "Hallo!"}]
  }'
```

**Systemprompt:** Im Modelfile eingebettet. Um ihn auszulesen:
```bash
ollama show sven-llama3.1:8b-instruct-q5_K_M --modelfile
```

---

### 2. `llama3.1:8b-instruct-q5_K_M`

| Eigenschaft | Wert |
|-------------|------|
| Basis-Modell | Meta Llama 3.1 8B Instruct |
| Quantisierung | Q5_K_M (~5 GB VRAM) |
| Typ | Standard-Modell (unverändert) |
| Hersteller | Meta AI |
| Kontext | 128.000 Token |

**Erklärung:** Das originale Llama 3.1 8B Instruct-Modell in Q5_K_M-Quantisierung. Optimiert für Instruktionsbefolgung (Chat), multilingual, gut auf Deutsch. Q5_K_M bietet eine gute Balance aus Qualität und Geschwindigkeit.

**API-Aufruf:**
```bash
# Mit eigenem Systemprompt zur Laufzeit
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.1:8b-instruct-q5_K_M",
  "messages": [
    {
      "role": "system",
      "content": "Du bist ein hilfreicher Assistent. Antworte immer auf Deutsch."
    },
    {
      "role": "user",
      "content": "Hallo!"
    }
  ],
  "stream": false
}'
```

**Standard-Systemprompt (Llama 3.1 Instruct):**
```
You are a helpful, respectful and honest assistant. Always answer as helpfully
as possible, while being safe. Your answers should not include any harmful,
unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure
that your responses are socially unbiased and positive in nature.

If a question does not make any sense, or is not factually coherent, explain
why instead of answering something not correct. If you don't know the answer
to a question, please don't share false information.
```
*(Eingebettet durch Meta im Instruct-Fine-Tuning; tatsächlich im Chat-Template, nicht als expliziter System-Turn)*

---

### 3. `Arena Model`

| Eigenschaft | Wert |
|-------------|------|
| Typ | Open WebUI Pseudo-Modell |
| Funktion | Blindes A/B-Modell-Vergleichstool |
| Backend | Wählt zufällig unter konfigurierten Modellen |

**Erklärung:** Das "Arena Model" ist kein eigenständiges KI-Modell, sondern eine **Open WebUI-Funktion** inspiriert vom LMSYS Chatbot Arena. Es leitet Anfragen verdeckt an verschiedene Modelle weiter, sodass der Nutzer ohne Wissen welches Modell geantwortet hat, zwischen den Antworten wählen kann – ein Qualitätsvergleich ohne Bias.

**API-Aufruf:** Nicht direkt via API erreichbar – nur über die Open WebUI-Oberfläche nutzbar.

---

## Infrastruktur

```
Nutzer (Sven)
    │
    ▼
Open WebUI  (Browser-Frontend, Port 3000)
    │
    ▼
Ollama  (Backend, Port 11434)
    │
    ├── sven-llama3.1:8b-instruct-q5_K_M  (Custom Modelfile)
    ├── llama3.1:8b-instruct-q5_K_M       (Standard)
    └── [Arena Model = Open WebUI Feature]
```

**Ollama REST API Endpunkte:**

| Endpunkt | Methode | Beschreibung |
|----------|---------|-------------|
| `/api/tags` | GET | Alle installierten Modelle auflisten |
| `/api/chat` | POST | Chat-Konversation |
| `/api/generate` | POST | Einfache Text-Vervollständigung |
| `/api/show` | POST | Modelldetails & Modelfile anzeigen |
| `/api/pull` | POST | Modell herunterladen |
| `/api/create` | POST | Modell aus Modelfile erstellen |
| `/v1/chat/completions` | POST | OpenAI-kompatibler Endpunkt |

---

## Systemprompt-Verwaltung

### Methode 1: Zur Laufzeit (pro Anfrage)

Geeignet für `llama3.1:8b-instruct-q5_K_M` und alle Standard-Modelle:

```json
{
  "model": "llama3.1:8b-instruct-q5_K_M",
  "messages": [
    {
      "role": "system",
      "content": "Du bist Sven's persönlicher Assistent. Du antwortest immer auf Deutsch, bist präzise und hilfreich."
    },
    {
      "role": "user",
      "content": "Was ist die Hauptstadt von Frankreich?"
    }
  ]
}
```

### Methode 2: Dauerhaft via Modelfile (wie bei `sven-llama3.1`)

```Dockerfile
FROM llama3.1:8b-instruct-q5_K_M

SYSTEM """
Du bist Sven's persönlicher KI-Assistent.
Antworte immer auf Deutsch, sei präzise und hilfsbereit.
Verhalte dich professionell und freundlich.
"""

PARAMETER temperature 0.7
PARAMETER top_k 40
PARAMETER top_p 0.9
```

```bash
# Modell erstellen
ollama create sven-llama3.1:8b-instruct-q5_K_M -f Modelfile

# Systemprompt des bestehenden Modells einsehen
ollama show sven-llama3.1:8b-instruct-q5_K_M --modelfile

# Modell direkt testen
ollama run sven-llama3.1:8b-instruct-q5_K_M
```

### Methode 3: Open WebUI System Prompt (pro Modell in der UI)

In Open WebUI unter **Einstellungen → Modelle** kann für jedes Modell ein Standard-Systemprompt hinterlegt werden, der in der Oberfläche aktiv bleibt – ohne Modelfile-Änderung.

---

## Quantisierungsübersicht (Q5_K_M)

| Eigenschaft | Q5_K_M | Vergleich |
|-------------|--------|-----------|
| Bits pro Gewicht | ~5.7 | Q4: ~4.5, Q8: ~8 |
| Qualitätsverlust | Minimal | Sehr gering |
| RAM-Bedarf (8B) | ~5.3 GB | Q4: ~4.5 GB, Q8: ~8 GB |
| Empfehlung | Beste Balance | Für die meisten Anwendungen ideal |
