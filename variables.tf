# =============================================
# variables.tf
# All configurable settings in one place
# =============================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "nhs_api_base_url" {
  description = "NHS BSA Open Data Portal API base URL"
  type        = string
  default     = "https://opendata.nhsbsa.net/api/3/action"
}

variable "nhs_dataset_id" {
  description = "NHS prescribing dataset ID"
  type        = string
  default     = "english-prescribing-data-epd"
}

variable "lambda_schedule" {
  description = "EventBridge schedule for Lambda trigger"
  type        = string
  default     = "cron(0 6 1 * ? *)"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 900
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "nhs_resource_id" {
  description = "NHS prescribing dataset resource ID"
  type        = string
  default     = "EPD_202506"
}
