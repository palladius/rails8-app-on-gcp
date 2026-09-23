variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the buckets."
  type        = string
  default     = "europe-west1"
}

variable "admin_account" {
  description = "The primary Google account for admin tasks and default blog administrator email."
  type        = string
  default     = ""
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

variable "allow_unauthenticated" {
  description = "Whether to allow public unauthenticated access (allUsers) to Cloud Run. Defaults to false to avoid Org Policy violations."
  type        = bool
  default     = false
}

variable "iap_allowed_users" {
  description = "List of Google accounts allowed to access the Cloud Run app through IAP or as authenticated invokers."
  type        = list(string)
  default     = []
}

variable "iap_client_id" {
  description = "OAuth2 Client ID for IAP (optional, required if enable_iap is true)."
  type        = string
  default     = ""
}

variable "iap_client_secret" {
  description = "OAuth2 Client Secret for IAP (optional, required if enable_iap is true)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_cicd_trigger" {
  description = "Whether to provision the automated GitHub push Cloud Build trigger (requires GitHub App integration)."
  type        = bool
  default     = false
}



