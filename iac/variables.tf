variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the buckets."
  type        = string
  default     = "europe-west1"
}

variable "developers" {
  description = "List of developer identities (e.g. 'user:you@gmail.com') allowed to sign GCS blob URLs locally via IAM signBlob."
  type        = list(string)
  default     = []
}

variable "enable_iap" {
  description = "Whether to provision an External HTTPS Application Load Balancer with Identity-Aware Proxy (IAP) in front of Cloud Run."
  type        = bool
  default     = false
}

variable "iap_allowed_users" {
  description = "List of Google accounts allowed to access the Cloud Run app through IAP."
  type        = list(string)
  default     = [
    "ricc@google.com",
    "emiliano.dellacasa@gmail.com"
  ]
}


