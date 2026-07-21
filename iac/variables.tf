variable "project_id" {
  description = "The GCP Project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the buckets."
  type        = string
  default     = "europe-west1"
}
