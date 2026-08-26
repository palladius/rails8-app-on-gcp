# Step 2: Cloud Storage

Currently, uploaded images are saved locally in the `storage/` folder. We will migrate ActiveStorage to Google Cloud Storage (GCS) using short-lived signed URLs.

1. Checkout the next branch:
   ```bash
   git checkout workshop_2_cloud_storage
   ```

2. Open `config/storage.yml` and inspect the `google` service definition:
   ```yaml
   google:
     service: GCS
     project: <%= ENV.fetch("GCP_PROJECT_ID") %>
     bucket: <%= ENV.fetch("GCS_BUCKET_NAME") %>
     iam: true  # Sign URLs via IAM Credentials signBlob API (no private key JSON required!)
   ```

3. Open `config/environments/production.rb` (and `development.rb` if testing remote storage locally) and set:
   ```ruby
   config.active_storage.service = :google
   ```

> 💡 **Design Decision — Why `iam: true` instead of `public: true`?**  
> Making a bucket public (`public: true` / `allUsers:objectViewer`) exposes every uploaded file to the entire internet forever. With `iam: true`, your bucket remains **100% private**, and Rails generates secure, short-lived signed URLs on the fly via the IAM Credentials API.

✨ **The Wow Moment:** Create or edit a post and drag-and-drop an image into the editor. Open your browser developer tools (Network tab) and Google Cloud Storage Console. You can see the image binary stream directly into your private GCS bucket, served back via an expiring secure signed URL!

