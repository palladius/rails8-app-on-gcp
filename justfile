# default recipe
default:
    @just --list

# show open issues via gh
status:
    gh issue list --state open

# install dependencies
install:
    cd blog && just install

# run the local development server
dev:
    cd blog && just dev

# start the local docker compose stack
compose-up:
    cd blog && just compose-up

# stop the local docker compose stack
compose-down:
    cd blog && just compose-down

# view docker compose logs
compose-logs:
    cd blog && just compose-logs

# run all tests
test:
    cd blog && just test

# autopush: run tests and push to origin main (GitHub Actions builds static pages on CI)
autopush:
    just test
    git push origin main

# run the workshop codelab visualizer server (serves /, /constitution, /skeleton, /a2ui)
workshop-dev port="8080":
    ruby workshop/visualizer/server.rb --port {{port}}

# run the Marp presentation slides server (default port: 8082)
slides port="8082":
    @if command -v marp >/dev/null 2>&1; then \
        PORT={{port}} marp --server slides --html; \
    else \
        PORT={{port}} npx -y @marp-team/marp-cli --server slides --html; \
    fi

# build static HTML slides into slides/dist/
build-slides:
    @mkdir -p slides/dist
    @if command -v marp >/dev/null 2>&1; then \
        marp slides/index.md -o slides/dist/index.html --html; \
    else \
        npx -y @marp-team/marp-cli slides/index.md -o slides/dist/index.html --html; \
    fi

# run visual and structural unit tests on Marp slides
test-slides:
    cd blog && bin/rails test test/integration/slides_presentation_test.rb

# run the workshop pre-flight diagnostics suite (validates Gmail identity, GCP billing, ADC, keys, canary asset)
workshop-test:
    @./bin/workshop_diagnostics.rb

# alias for workshop-test
workshop-check:
    @just workshop-test

# estimate live GCP incurred costs and remaining $5 GDP credits
billing-estimate hours="6.0":
    @./bin/rails8app-billing --hours {{hours}}

# alias for billing-estimate
billing hours="6.0":
    @just billing-estimate {{hours}}




# show project status
project-status:
    cd iac && ./check_gcp_setup.sh
    cd blog && echo "\n=== 5️⃣ Checking DB Posts ===" && bundle exec rails runner 'puts "  📊 Posts in DB: #{Post.count rescue "No DB/Posts yet"}"' || true

# check the live status of the Cloud Run deployment (infers URL from Terraform or gcloud)
cloud-run-status url="":
    @./bin/cloud_run_status.sh {{url}}

seed:
	cd blog && rake db:seed

# check the status of conductor tracks
conductor-status:
	./conductor/bin/conductor-inspector --all --short

# apply terraform changes
terraform-apply:
	cd iac && terraform apply

# compile workshop/SKELETON.md from workshop/skeleton.yaml
build-skeleton:
	ruby workshop/visualizer/build_skeleton.rb

# rewind configuration to workshop stage (1: stateless SQLite, 2: GCS private storage)
workshop-rewind stage="1":
	ruby bin/workshop_time_machine.rb rewind {{stage}}

# restore configuration to canonical gold standard (main)
workshop-restore-gold:
	ruby bin/workshop_time_machine.rb restore-gold

# run automated evaluations on workshop steps (default: step 0 or specify step)
workshop-eval step="all":
	ruby bin/workshop_eval.rb {{step}}

# run fast end-to-end UAT test for a workshop step in an isolated local git clone
workshop-uat step="1":
	ruby bin/workshop_uat.rb {{step}}

# Generate static HTML for GitHub pages from CODELAB.md and SKELETON.md
build-ghpages:
	just build-skeleton
	ruby workshop/visualizer/build_ghpages.rb

# show registered users in a clean CLI table ordered by created_at DESC
show-users:
	cd blog && just show-users


list:
    @just --list
    gh issue list
