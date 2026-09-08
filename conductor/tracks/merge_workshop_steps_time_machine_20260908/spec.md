# Specification: Merge workshop/steps into time-machine while preserving legacy test resources

> **Track ID:** `merge_workshop_steps_time_machine_20260908`  
> **Target Issue:** [#28 (Child of #2)](https://github.com/palladius/rails8-app-on-gcp/issues/28)  
> **Status:** In Progress  
> **Type:** Refactor & Time-Machine

---

## 1. Overview & Context
Attualmente `workshop/steps/` contiene frammenti sparsi di codice e test ereditati da un vecchio workflow su branch:
- `page1_vanilla/`: SQLite locale (`database.yml`, `storage.yml`, `production.rb`, `test.rb`).
- `page2_cloud_storage/`: configurazioni GCS + test (`storage_config_test.rb`, `broken_images_test.rb`, `cloud_storage_configuration_test.rb`, `post_test.rb`).
- `page3_cloud_sql/`: `database.yml` con Cloud SQL postgresql.
- `page5_cloud_run/`: `compose.prod.yaml`, `docker-compose.yml`, `cloud_run_configuration_test.rb`.
- `page6_cicd/`: `.github/workflows/ci.yml`.

Parallelamente, la Costituzione v1.1.0 e la GHI #23 definiscono il paradigma **Zero-Branch Time-Machine** su `main`, con comandi `just workshop-rewind <N>` e `just workshop-restore-gold`.

## 2. Requirements & Migration Mapping

1. **Costruzione di `workshop/time-machine/`**:
   - `workshop/time-machine/stage-1-stateless/`:
     - `blog/config/database.yml` (SQLite on disk)
     - `blog/config/storage.yml` (Disk local storage)
   - `workshop/time-machine/stage-2-gcs/`:
     - `blog/config/storage.yml` (ActiveStorage con GCS IAM signing)
     - `blog/config/database.yml` (ancora SQLite locale)
   - `workshop/time-machine/stage-3-gold/`:
     - Snapshot o puntatore di ripristino alle configurazioni complete di `main`.

2. **Preservazione dei Test Utili nella Test Suite Principale (`blog/test/`)**:
   - `storage_config_test.rb`: suite essenziale che valida `config/storage.yml` contro regressioni su private IAM signing e bucket namespacing. Da promuovere a test ufficiale in `blog/test/config/storage_config_test.rb`!
   - `cloud_run_configuration_test.rb`: test che valida la struttura di `compose.prod.yaml` (`web`, `worker`, `cloudsql-proxy`). Da promuovere a test ufficiale in `blog/test/integration/cloud_run_configuration_test.rb` (adattato alla sintassi attuale di `compose.prod.yaml`).

3. **Integrazione in `justfile`**:
   - `just workshop-rewind stage`: applica l'overlay del Time-Machine desiderato (1 o 2).
   - `just workshop-restore-gold`: ripristina la configurazione di `main` (`git checkout blog/config/`).

4. **Rimozione sicura di `workshop/steps/`**:
   - Eliminazione completa della vecchia cartella obsoleta dopo aver verificato che ogni risorsa di valore è stata integrata.
