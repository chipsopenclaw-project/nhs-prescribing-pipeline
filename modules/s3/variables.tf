# =============================================
# modules/s3/variables.tf
# =============================================

variable "environment" {
  description = "Deployment environment (dev, stg, prd)"
  type        = string
}
