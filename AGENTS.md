# Agents

This is a file for Gemini and Claude to read.
Riccardo and Emiliano collaborate on this amazing thingy which is bifidus (two-fold):
1. A code repo with an existing rails app, under `blog/`. This is an ambitious "Rails 8 blueprint, compatible with GCP", with all the I's dotted.
2. A workshop which makes sense of this repo, takes a student by the hand to reach awesomeness. The flow: you download the repo, use Gemini to do something cool with it locally, deploy to GCP, and set up additional goodies like GCS.
3. Branding: We work for Google, so colors/branding should look colorful and fun!
4. Incremental Workshop: While working on the app, we MUST incrementally build a multipage workshop under `workshop/`. Add notes on design decisions as we go (e.g., why docker compose this way?) so we don't forget the minutiae.

## GCP and workshop notes

1. `Activestorage`+`GCS` has always been a pain for Riccardo to setup. This needs to be properly tested with non-public objects.
2. We want to demonstrate `docker-compose` in Cloud Run. Rubyists nowadays are skeptical about the Cloud, they use Kamal and SQlite love Cloud re-patriation. To win their heart we need to meet them where they are: in localhost and baremetal - or make GCP look like it as much as possible :)
3. I think we can skip kafka/PubSub and use DB queues. This was Emiliano suggestion and I think this is what the chat 2026 uses. Please doouble check it, and I'm happy to take a critical look at other options leveraging `docker-compose`.
4. Use Fabric FAST for GCP Terraform, also for Terraform read `iac/README.md` and `iac/AGENTS.md` which contains important dispositions

## Folder structure

* App is under `blog/`
* Workshop is (temporarily) under `workshop/`. Additional instructions can be found in `workshop/AGENTS.md`.
* GCP setup is going under `iac/`. This will include Cloud Build yamls, terraform code for setup, bash scripts, ...
* Do not use EXTERNAL symlinks, copy the whole app in here, maybe without `.env`. ;)

## AI Dev

To code, we use Gemini and the Conductor skill. Ensure you install the conductor skill here: https://github.com/gemini-cli-extensions/conductor
* Ensure proper versioning is happening in `CHANGELOG.md`. This needs to align to app version. this is super important for workshops, so we can say "since/until v1.2.3 this /wasis...", great for errata.
* You decide where version is, but it needs to be surfaced in footer, alongside a link to GH code!
* Use TDD -> Start with a broken test, prove it FAILS first, and change code until it works!
* Ensure all tests pass., and not because you comment them out! do not commit unless `just test` which runs all rails tests + other stuff (eg some TF or other ext stuff) pass. If user is in a hurry, its ok to commit but confirm with user first. Lets try NOt to push broken commits.

## Personas

* When Addressing Riccardo, call him "Supreme Leader and pun-master"
* When addressing Emiliano, call him "Al Mudnais cal'scorda i symlink" with some fun emojis.

## Repos

This is the last fo 3 repos for the Rails 8 on GCP workshop, tying together 3 public repos:

- 🟢 **rails8-app-on-gcp** (THIS ONE) — The new canonical app + GCP plumbing
- 🟡 **rails8-turbo-chat** (THE PAST) — Riccardo's original chat app, battle-tested GCP configs
  - TODO git cponfig
- 🔵 **rails8-turbo-chat-2026** (GCP INSPIRATION) — Emiliano's clean GCP-native fork
  - todo git config. 
- In Riccardo config, they're available under ~/git/<REPONAME>