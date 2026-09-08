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
    cd workshop && ./server.rb --port {{port}}

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


# show project status
project-status:
    cd iac && ./check_gcp_setup.sh
    cd blog && echo "\n=== 5️⃣ Checking DB Posts ===" && bundle exec rails runner 'puts "  📊 Posts in DB: #{Post.count rescue "No DB/Posts yet"}"' || true

seed:
	cd blog && rake db:seed

# check the status of conductor tracks
conductor-status:
	./conductor/bin/conductor-inspector --all --short

# apply terraform changes
terraform-apply:
	cd iac && terraform apply

# Generate static HTML for GitHub pages from CODELAB.md
build-ghpages:
	cd workshop && ruby split_codelab.rb
	cd workshop && ruby build_ghpages.rb

# show registered users in a clean CLI table ordered by created_at DESC
show-users:
	cd blog && just show-users


list:
    @just --list
    gh issue list
