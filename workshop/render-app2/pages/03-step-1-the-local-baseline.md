# Step 1: The Local Baseline

Our starting point is a standard Rails 8 blog application. It uses SQLite for the database and stores images on your local hard drive. 

Run the setup commands to get the app running locally:

```bash
bundle install
bin/rails db:setup
bin/dev
```

Open `http://localhost:3000` in your browser. You should see a basic blog. Try creating a post and uploading an image. It works perfectly on your machine!

**The Catch:** Cloud Run containers are stateless. If we deploy this right now, your SQLite database and local images will be wiped out every time the container restarts. We need to move our state to the cloud.

### Provisioning the Cloud Infrastructure

Cloud SQL takes about 15 minutes to provision. Let's start that process now so it's ready when we need it!

Open a new terminal tab and run:

```bash
cd iac/
terraform init
terraform apply -auto-approve
```

While Terraform does the heavy lifting in the background, let's fix our storage!

