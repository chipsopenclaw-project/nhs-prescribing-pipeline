# =============================================
# modules/lambda/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda IAM execution role"
  type        = string
}

variable "bronze_bucket_name" {
  description = "Name of the S3 bronze bucket"
  type        = string
}

variable "nhs_api_base_url" {
  description = "NHS BSA Open Data Portal API base URL"
  type        = string
}

variable "nhs_dataset_id" {
  description = "NHS prescribing dataset ID"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
}

variable "glue_workflow_name" {
  description = "Name of the Glue workflow to trigger after upload"
  type        = string
}
