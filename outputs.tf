# =============================================
# outputs.tf
# Displays key resource info after
# terraform apply completes
# =============================================

# ---------------------------
# S3 Buckets
# ---------------------------
output "bronze_bucket_name" {
  description = "S3 bronze bucket name"
  value       = module.s3.bronze_bucket_name
}

output "silver_bucket_name" {
  description = "S3 silver bucket name"
  value       = module.s3.silver_bucket_name
}

output "gold_bucket_name" {
  description = "S3 gold bucket name"
  value       = module.s3.gold_bucket_name
}

output "athena_bucket_name" {
  description = "S3 Athena results bucket name"
  value       = module.s3.athena_bucket_name
}

# ---------------------------
# Lambda
# ---------------------------
output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.lambda_func_name
}

output "lambda_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.lambda_arn
}

# ---------------------------
# EventBridge
# ---------------------------
output "eventbridge_rule_name" {
  description = "EventBridge schedule rule name"
  value       = module.eventbridge.event_rule_name
}

# ---------------------------
# Glue
# ---------------------------
output "glue_database_name" {
  description = "Glue catalog database name"
  value       = module.glue.glue_database_name
}

output "glue_crawler_name" {
  description = "Glue bronze crawler name"
  value       = module.glue.glue_crawler_name
}

output "bronze_to_silver_job_name" {
  description = "Glue Bronze to Silver job name"
  value       = module.glue.bronze_to_silver_job_name
}

output "silver_to_gold_job_name" {
  description = "Glue Silver to Gold job name"
  value       = module.glue.silver_to_gold_job_name
}

# ---------------------------
# Athena
# ---------------------------
output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = module.athena.workgroup_name
}

# ---------------------------
# Streamlit configuration
# Copy these values into your Streamlit app
# ---------------------------
output "streamlit_config" {
  description = "Config values needed for Streamlit app"
  value = {
    aws_region         = var.aws_region
    athena_workgroup   = module.athena.workgroup_name
    athena_database    = module.glue.glue_database_name
    athena_s3_results  = "s3://${module.s3.athena_bucket_name}/query-results/"
    gold_bucket        = module.s3.gold_bucket_name
  }
}
