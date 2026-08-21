#!/bin/bash

set -e

# Make sure we are at the root of the repo
if [ ! -d "workshop/steps" ]; then
  echo "Error: Must be run from the root of the rails8-app-on-gcp repository."
  exit 1
fi

BASE_BRANCH="main"

# Define the steps and their branch names
STEPS=(
  "page1_vanilla:workshop/page1"
  "page2_cloud_storage:workshop/page2"
  "page3_cloud_sql:workshop/page3"
  "page4_secret_manager:workshop/page4"
  "page5_cloud_run:workshop/page5"
  "page6_cicd:workshop/page6"
  "page7_ai:workshop/page7"
)

echo "🗑️  Deleting old branches..."
for step_info in "${STEPS[@]}"; do
  IFS=':' read -r step_folder branch_name <<< "$step_info"
  git branch -D "$branch_name" 2>/dev/null || true
done

echo "🌱 Starting branch generation from $BASE_BRANCH..."
git checkout "$BASE_BRANCH"

PREVIOUS_BRANCH="$BASE_BRANCH"

for step_info in "${STEPS[@]}"; do
  # Parse the step folder and target branch name
  IFS=':' read -r step_folder branch_name <<< "$step_info"
  
  echo "========================================"
  echo "🚀 Generating $branch_name from $PREVIOUS_BRANCH..."
  
  # Checkout the new branch from the previous one
  git checkout -b "$branch_name" "$PREVIOUS_BRANCH"
  
  # Copy the hidden bag files for this step if the folder exists and is not empty
  if [ -d "workshop/steps/$step_folder" ] && [ "$(ls -A workshop/steps/$step_folder 2>/dev/null)" ]; then
    echo "📦 Applying patch from workshop/steps/$step_folder..."
    cp -R workshop/steps/"$step_folder"/* .
    
    # Add and commit the changes
    git add .
    git commit -m "Apply $step_folder patch"
  else
    echo "⚠️  No patch found or folder empty for $step_folder. Branch created identical to previous."
  fi
  
  echo "🧪 Running tests for $branch_name..."
  if [ -d "blog" ]; then
    (cd blog && bundle config set --local path 'vendor/bundle' && bundle install && bundle exec rails test)
    if [ $? -ne 0 ]; then
      echo "❌ Tests failed for $branch_name! Aborting generation."
      exit 1
    fi
    echo "✅ Tests passed for $branch_name!"
  else
    echo "⚠️  No 'blog' directory found, skipping tests."
  fi
  
  PREVIOUS_BRANCH="$branch_name"
done

echo "✅ All branches generated successfully!"
# Return to the base branch
git checkout "$BASE_BRANCH"
