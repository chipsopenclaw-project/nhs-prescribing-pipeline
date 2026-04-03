# =============================================
# modules/lambda/main.tf
# Creates Lambda function that:
#   - Fetches NHS CSV from API
#   - Uploads raw CSV to S3 bronze bucket
# =============================================

locals {
  lambda_name = "ukb-${var.environment}-euw2-lambda-nhs-fetcher"
}

# Auto-package handler.py into ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/lambda_src"
  output_path = "${path.root}/lambda_src.zip"
  excludes    = ["glue_bronze_to_silver.py", "glue_silver_to_gold.py"]
}

# Lambda function
resource "aws_lambda_function" "nhs_fetcher" {
  function_name    = local.lambda_name
  role             = var.lambda_role_arn
  runtime          = "python3.11"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  environment {
    variables = {
      BRONZE_BUCKET_NAME = var.bronze_bucket_name
      NHS_API_BASE_URL   = var.nhs_api_base_url
      NHS_DATASET_ID     = var.nhs_dataset_id
      GLUE_WORKFLOW_NAME = var.glue_workflow_name
    }
  }
}
