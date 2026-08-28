###############################################################################
# Optional: Identity-Aware Proxy (IAP) & External Load Balancer for Cloud Run
# Controlled by var.enable_iap (defaults to false to prevent LB idle costs).
###############################################################################

# Required GCP APIs for IAP and Load Balancing
resource "google_project_service" "iap_api" {
  count              = var.enable_iap ? 1 : 0
  project            = var.project_id
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  count              = var.enable_iap ? 1 : 0
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# 1. Serverless Network Endpoint Group (NEG) pointing to the Cloud Run service
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  count                 = var.enable_iap ? 1 : 0
  name                  = "${var.project_id}-rails-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.rails_app.name
  }

  depends_on = [google_project_service.compute_api]
}

# 2. Backend Service with IAP enabled
resource "google_compute_backend_service" "iap_backend" {
  count                 = var.enable_iap ? 1 : 0
  name                  = "${var.project_id}-iap-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg[0].id
  }

  iap {
    enabled = true
  }

  depends_on = [google_project_service.iap_api]
}

# 3. URL Map to route traffic to the IAP backend
resource "google_compute_url_map" "iap_url_map" {
  count           = var.enable_iap ? 1 : 0
  name            = "${var.project_id}-iap-url-map"
  default_service = google_compute_backend_service.iap_backend[0].id
}

# 4. HTTP Proxy and Global Forwarding Rule
resource "google_compute_target_http_proxy" "iap_http_proxy" {
  count   = var.enable_iap ? 1 : 0
  name    = "${var.project_id}-iap-http-proxy"
  url_map = google_compute_url_map.iap_url_map[0].id
}

resource "google_compute_global_forwarding_rule" "iap_forwarding_rule" {
  count                 = var.enable_iap ? 1 : 0
  name                  = "${var.project_id}-iap-forwarding-rule"
  target                = google_compute_target_http_proxy.iap_http_proxy[0].id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# 5. Grant roles/iap.httpsResourceAccessor to allowed Google accounts
resource "google_iap_web_backend_service_iam_member" "iap_accessors" {
  for_each            = var.enable_iap ? toset(var.iap_allowed_users) : toset([])
  project             = var.project_id
  web_backend_service = google_compute_backend_service.iap_backend[0].name
  role                = "roles/iap.httpsResourceAccessor"
  member              = startswith(each.value, "user:") || startswith(each.value, "group:") || startswith(each.value, "domain:") ? each.value : "user:${each.value}"
}
