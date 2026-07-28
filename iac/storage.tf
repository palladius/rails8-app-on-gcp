###############################################################################
# ActiveStorage: GCS Buckets (dev, test, prod) + Seed Images
###############################################################################

# Development Bucket
module "gcs_dev" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id    = var.project_id
  name          = "${var.project_id}-activestorage-dev"
  location      = var.region
  force_destroy = true
}

# Test Bucket
module "gcs_test" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id    = var.project_id
  name          = "${var.project_id}-activestorage-test"
  location      = var.region
  force_destroy = true
}

# Production Bucket
module "gcs_prod" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/gcs?ref=v34.0.0"
  project_id = var.project_id
  name       = "${var.project_id}-activestorage-prod"
  location   = var.region
}

# Seed Images for ActiveStorage End-to-End Testing
resource "google_storage_bucket_object" "dev_seed_image" {
  name   = "seeds/gcs_dev_image.jpg"
  bucket = module.gcs_dev.name
  source = "../blog/app/assets/images/gcs_dev_image.jpg"
}

resource "google_storage_bucket_object" "test_seed_image" {
  name   = "seeds/gcs_test_image.jpg"
  bucket = module.gcs_test.name
  source = "../blog/app/assets/images/gcs_test_image.jpg"
}

resource "google_storage_bucket_object" "prod_seed_image" {
  name   = "seeds/gcs_prod_image.jpg"
  bucket = module.gcs_prod.name
  source = "../blog/app/assets/images/gcs_prod_image.jpg"
}
