# =============================================
# modules/iam/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}

variable "bronze_bucket_arn" {
  description = "ARN of the bronze S3 bucket"
  type        = string
}

variable "silver_bucket_arn" {
  description = "ARN of the silver S3 bucket"
  type        = string
}

variable "gold_bucket_arn" {
  description = "ARN of the gold S3 bucket"
  type        = string
}

variable "athena_bucket_arn" {
  description = "ARN of the Athena results S3 bucket"
  type        = string
}
variable "scripts_bucket_arn" {
  description = "ARN of the S3 scripts bucket"
  type        = string
}
