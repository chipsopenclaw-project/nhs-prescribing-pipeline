# =============================================
# modules/glue/outputs.tf
# =============================================

output "glue_database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.nhs.name
}

output "glue_crawler_name" {
  description = "Name of the Glue bronze crawler"
  value       = aws_glue_crawler.bronze.name
}

output "bronze_to_silver_job_name" {
  description = "Name of the Bronze to Silver Glue job"
  value       = aws_glue_job.bronze_to_silver.name
}

output "silver_to_gold_job_name" {
  description = "Name of the Silver to Gold Glue job"
  value       = aws_glue_job.silver_to_gold.name
}

output "workflow_name" {
  description = "Name of the Glue workflow"
  value       = aws_glue_workflow.nhs_pipeline.name
}

output "start_crawler_trigger_name" {
  description = "Name of the ON_DEMAND trigger to start workflow"
  value       = aws_glue_trigger.start_crawler.name
}

output "api_to_bronze_job_name" {
  description = "Name of the API to Bronze Glue job"
  value       = aws_glue_job.api_to_bronze.name
}
