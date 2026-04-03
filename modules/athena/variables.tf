# =============================================
# modules/athena/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}

variable "athena_bucket_name" {
  description = "Name of the S3 bucket for Athena query results"
  type        = string
}

variable "gold_bucket_arn" {
  description = "ARN of the S3 gold bucket"
  type        = string
}

variable "glue_database_name" {
  description = "Name of the Glue catalog database"
  type        = string
}
