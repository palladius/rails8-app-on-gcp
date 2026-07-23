## Workshop ideas

* [Emiliano] At the beginning, ask user to add user and password to seeds for login.
* [Riccardo] At beginning ask Gemini to TAL at models and make an E/R diagram using mermaid and embed/render in README.md (or a new ARCHITECTURE.md)
* [Riccardo] Explain ActiveStorage image handling across environments: have a v1 branch where images are saved locally, and a v2 branch where images are migrated/configured for remote GCS.

## App notes

* Let's ensure we prevent bad Data currptuion, like db:seed populating the same post more than once, at the cost of addinhg stupid primary keys, eg Post `title` uniqueness.
