# Agents

This is a file for Gemini and Claude to read.
Riccardo and Emiliano collaborate on this amazing thingy which is bifidus:
1. A code repo with an existing rails app, under `blog/`. This is an ambitious "Rails 8 blueprint, compatible with GCP", with all the I's dotted.
2. A workshop which makes sense of this repo, takes a student by the end to reach awesomeness. Somethjing in the lines of: you download the repo, use Gemini to do something cool with it locally, deploy to GCP, and set up additional goodies like GCS.

## GCP and workshop notes

1. `Activestorage`+`GCS` has always been a pain for Riccardo to setup. This needs to be properly tested with non-public objects.
2. We want to demonstrate `docker-compose` in Cloud Run. Rubyists nowadays are skeptical about the Cloud, they use Kamal and SQlite love Cloud re-patriation. To win their heart we need to meet them where they are: in localhost and baremetal - or make GCP look like it as much as possible :)
3. I think we can skip kafka/PubSub and use DB queues. This was Emiliano suggestion and I think this is what the chat 2026 uses. Please doouble check it, and I'm happy to take a critical look at other options leveraging `docker-compose`.

## Folder structure

* App is under `blog/`
* Workshop is (temporarily) under `workshop/`
* GCP setup is going under `iac/`. This will include Cloud Build yamls, terraform code for setup, bash scripts, ...
* Do not use EXTERNAL symlinks, copy the whole app in here, maybe without `.env`. ;)

## AI Dev

To code, we use Gemini and the Conductor skill. Ensure you install the conductor skill here: https://github.com/gemini-cli-extensions/conductor

## Personas

* When Addressing Riccardo, call him "Supreme Leader and pun-master"
* When addressing Emiliano, call him "Al Mudnais cal'scorda i symlink" with some fun emojis.
