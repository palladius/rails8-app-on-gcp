# Specification: Declarative Workshop Skeleton in YAML with Automated Hybrid & LLM EVALs

> **Track ID:** `declarative_skeleton_yaml_20260908`  
> **Target Issue:** [#31 (Child of #2)](https://github.com/palladius/rails8-app-on-gcp/issues/31)  
> **Status:** Confirmed  
> **Type:** Refactor & Architecture

---

## 1. Overview & Vision
Attualmente `workshop/SKELETON.md` contiene la sequenza degli step del workshop in formato Markdown ad uso umano. Tuttavia, non è agevolmente interrogabile programmaticamente né consente a Google Antigravity o alla CI di verificare in automatico se uno studente ha completato con successo uno step.

Questo track introduce **`workshop/skeleton.yaml`** come **Single Source of Truth** dichiarativa e strutturata per l'intero workshop. Da questo file:
1. Viene compilato automaticamente `workshop/SKELETON.md` garantendo consistenza al 100%.
2. Viene fornito un motore di valutazione (`just workshop-eval [step]`) in grado di testare la corretta esecuzione di ciascun passaggio con test deterministici e giudici GenAI.

---

## 2. Functional Requirements

### 2.1 Schema del File `workshop/skeleton.yaml`
Ogni step contiene i seguenti campi:
- **`step`**: Identificativo univoco (es. `step-0`, `step-1`, ..., `step-8`).
- **`title`**: Titolo chiaro del passaggio.
- **`description`**: Breve spiegazione concettuale (max 2-3 frasi).
- **`pseudocode`**: Implementazione high-level (max 4-5 righe di comandi shell chiari, es. `cp .env.dist .env && vim .env && just terraform-apply`).
- **`prerequisites`**: Lista puntata delle condizioni richieste prima di iniziare lo step.
- **`postrequisites`**: Delta architetturale e benefici acquisiti dopo il completamento dello step.
- **`evals`**: Array di verifiche eterogenee che supportano 3 tipologie:
  1. **Tipo `shell`**:
     - `type`: "shell"
     - `command`: comando bash da eseguire
     - `expect_exit`: codice di uscita atteso (es. `0`)
     - `description`: descrizione del test
  2. **Tipo `ruby`**:
     - `type`: "ruby"
     - `code` o `script`: asserzione/snippet Ruby da eseguire nel contesto Rails o Standalone
     - `description`: spiegazione della verifica
  3. **Tipo `llm` (LLM-as-a-Judge)**:
     - `type`: "llm"
     - `prompt`: prompt inviato al modello LLM (Gemini via Vertex AI / ADC) per valutare un artefatto o output dello studente.
     - `schema_output`: JSON strutturato obbligatorio restituito dal modello:
       ```json
       {
         "return": 0,
         "comment": "optional feedback for the student",
         "error_message": "string obbligatoria se return != 0"
       }
       ```
     - `description`: cosa sta valutando l'LLM (es. "Verifica che il post creato abbia stile e requisiti conformi").

### 2.2 Generatore & Sincronizzatore (`workshop/visualizer/build_skeleton.rb`)
- Script Ruby che legge `workshop/skeleton.yaml` e rigenera fedelmente `workshop/SKELETON.md`.
- Integrato nel comando `just build-ghpages` o in una ricetta dedicata `just build-skeleton`.

### 2.3 Runner di Valutazione (`bin/workshop_eval.rb`)
- Runner per eseguire le `evals` per step:
  - `just workshop-eval 1`: esegue solo le `evals` definite per lo Step 1.
  - `just workshop-eval all`: esegue la suite completa per verificare l'intero workshop.
  - Supporta esecuzione dei check `shell`, `ruby` ed `llm`.

---

## 3. Acceptance Criteria
- [ ] Esiste `workshop/skeleton.yaml` valido, contenente tutti gli 8 Step allineati con la Costituzione v1.1.0 e la narrativa dei 3 Deploy.
- [ ] Supporto completo in `evals` per check di tipo `shell`, `ruby` e `llm` con formato JSON conforme.
- [ ] `workshop/SKELETON.md` viene generato deterministicamente da `skeleton.yaml`.
- [ ] Runner `bin/workshop_eval.rb` implementato e funzionante con `just workshop-eval [step]`.
