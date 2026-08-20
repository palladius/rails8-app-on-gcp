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
