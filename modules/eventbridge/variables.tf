# =============================================
# modules/eventbridge/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function to trigger"
  type        = string
}

variable "lambda_func_name" {
  description = "Name of the Lambda function to trigger"
  type        = string
}

variable "lambda_schedule" {
  description = "EventBridge schedule expression"
  type        = string
}
