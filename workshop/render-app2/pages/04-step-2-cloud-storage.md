# Step 2: Cloud Storage

Currently, our blog images are stored in the `storage/` directory locally. We need to move this to Google Cloud Storage (GCS) so our images survive container restarts.

Our Terraform script is already creating a GCS bucket for us. Let's configure Rails to use it.

1. Checkout the next branch:
   ```bash
   git checkout workshop_2_cloud_storage
   ```
2. Open `config/storage.yml` and look at the `google` service definition. We use the `google-cloud-storage` gem to connect to our bucket.
3. Open `config/environments/production.rb` (and `development.rb` if you want to test locally) and change the ActiveStorage service:
   ```ruby
   config.active_storage.service = :google
   ```
4. Keep the bucket **private**, and tell Rails how to sign URLs without a key. Cloud Run authenticates through the metadata server, which hands out access tokens but no private key — so Rails cannot compute a GCS signature on its own, and every image blows up with `Service account credentials 'issuer (client_email)' is missing`. One line per service in `config/storage.yml` fixes it:
   ```yaml
   iam: true  # sign via the IAM Credentials signBlob API — no private key needed
   ```

   > 💡 **Design decision:** the tempting shortcut is `public: true` plus an `allUsers:objectViewer` grant on the bucket. Don't: it makes every upload world-readable forever, and those URLs never expire. Signing through the IAM Credentials API keeps blobs private behind expiring signed URLs, and costs exactly one extra IAM role — `roles/iam.serviceAccountTokenCreator` on the service account *itself*, already wired up in our Terraform.

Restart your Rails server and try creating a new post with an image. The image is now safely stored in a Google Cloud Storage bucket!

