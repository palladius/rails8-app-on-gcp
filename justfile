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

# run all tests
test:
    cd blog && just test

# autopush: run tests, rebuild static pages, and push to origin main
autopush:
    just test
    just build-ghpages
    git push origin main

# run the workshop codelab visualizer server
workshop-dev port="8080":
    cd workshop && ./server.rb --port {{port}}

# run the workshop visualizer directly focused on the Untouchable Constitution
workshop-constitution port="8081":
    cd workshop && ./server.rb --port {{port}} UNTOUCHABLE-CONSTITUTION.md

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
