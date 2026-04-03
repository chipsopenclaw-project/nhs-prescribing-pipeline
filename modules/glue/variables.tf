# =============================================
# modules/glue/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the Glue IAM execution role"
  type        = string
}

variable "bronze_bucket_name" {
  description = "Name of the S3 bronze bucket"
  type        = string
}

variable "silver_bucket_name" {
  description = "Name of the S3 silver bucket"
  type        = string
}

variable "gold_bucket_name" {
  description = "Name of the S3 gold bucket"
  type        = string
}

variable "scripts_bucket" {
  description = "Name of the S3 scripts bucket"
  type        = string
}

variable "nhs_api_base_url" {
  description = "NHS BSA Open Data Portal API base URL"
  type        = string
}

variable "nhs_resource_id" {
  description = "NHS prescribing dataset resource ID"
  type        = string
}
