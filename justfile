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
# show project status
project-status:
    cd iac && ./check_gcp_setup.sh
    cd blog && echo "\n=== 5️⃣ Checking DB Posts ===" && bundle exec rails runner 'puts "  📊 Posts in DB: #{Post.count rescue "No DB/Posts yet"}"' || true

seed:
	cd blog && rake db:seed

# check the status of conductor tracks
conductor-status:
	agc mcp call conductor conductor-status

# apply terraform changes
terraform-apply:
	cd iac && terraform apply
