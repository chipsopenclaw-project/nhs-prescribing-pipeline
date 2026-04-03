# =============================================
# modules/glue/main.tf
# Creates:
#   - Glue Database
#   - Glue Crawler
#   - Glue Job 0: API to Bronze
#   - Glue Job 1: Bronze to Silver
#   - Glue Job 2: Silver to Gold
#   - Glue Workflow + Triggers
# =============================================

locals {
  prefix = "ukb-${var.environment}-euw2"
}

# ---------------------------
# Glue Database
# ---------------------------
resource "aws_glue_catalog_database" "nhs" {
  name        = "ukb_${var.environment}_nhs_prescribing_db"
  description = "NHS prescribing data catalog database"
}

# ---------------------------
# Upload Glue scripts to S3
# ---------------------------
resource "aws_s3_object" "api_to_bronze_script" {
  bucket = var.scripts_bucket
  key    = "scripts/glue_api_to_bronze.py"
  source = "${path.root}/lambda_src/glue_api_to_bronze.py"
  etag   = filemd5("${path.root}/lambda_src/glue_api_to_bronze.py")
}

resource "aws_s3_object" "bronze_to_silver_script" {
  bucket = var.scripts_bucket
  key    = "scripts/glue_bronze_to_silver.py"
  source = "${path.root}/lambda_src/glue_bronze_to_silver.py"
  etag   = filemd5("${path.root}/lambda_src/glue_bronze_to_silver.py")
}

resource "aws_s3_object" "silver_to_gold_script" {
  bucket = var.scripts_bucket
  key    = "scripts/glue_silver_to_gold.py"
  source = "${path.root}/lambda_src/glue_silver_to_gold.py"
  etag   = filemd5("${path.root}/lambda_src/glue_silver_to_gold.py")
}

# ---------------------------
# Glue Crawler
# ---------------------------
resource "aws_glue_crawler" "bronze" {
  name          = "${local.prefix}-glue-nhs-bronze-crawler"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.nhs.name
  description   = "Crawls NHS bronze Parquet and updates Glue catalog"

  s3_target {
    path = "s3://${var.bronze_bucket_name}/prescribing/bronze/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

# ---------------------------
# Glue Job 0: API to Bronze
# ---------------------------
resource "aws_glue_job" "api_to_bronze" {
  name         = "${local.prefix}-glue-nhs-api-to-bronze"
  role_arn     = var.glue_role_arn
  description  = "Fetches NHS data from CKAN API and writes to Bronze"
  glue_version = "4.0"
  max_retries  = 1
  timeout      = 480

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.scripts_bucket}/scripts/glue_api_to_bronze.py"
  }

  default_arguments = {
    "--job-language"              = "python"
    "--enable-job-insights"       = "true"
    "--enable-auto-scaling"       = "true"
    "--BRONZE_BUCKET"             = var.bronze_bucket_name
    "--API_BASE_URL"              = var.nhs_api_base_url
    "--RESOURCE_ID"               = var.nhs_resource_id
    "--TempDir"                   = "s3://${var.scripts_bucket}/tmp/"
    "--additional-python-modules" = "requests==2.31.0,pandas==2.0.3,pyarrow==12.0.1"
  }

  worker_type       = "G.1X"
  number_of_workers = 4
}

# ---------------------------
# Glue Job 1: Bronze to Silver
# ---------------------------
resource "aws_glue_job" "bronze_to_silver" {
  name         = "${local.prefix}-glue-nhs-bronze-to-silver"
  role_arn     = var.glue_role_arn
  description  = "Cleans NHS Bronze data and writes Silver Parquet"
  glue_version = "4.0"
  max_retries  = 1
  timeout      = 60

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.scripts_bucket}/scripts/glue_bronze_to_silver.py"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--enable-auto-scaling" = "true"
    "--BRONZE_BUCKET"       = var.bronze_bucket_name
    "--SILVER_BUCKET"       = var.silver_bucket_name
    "--TempDir"             = "s3://${var.scripts_bucket}/tmp/"
  }

  worker_type       = "G.1X"
  number_of_workers = 2
}

# ---------------------------
# Glue Job 2: Silver to Gold
# ---------------------------
resource "aws_glue_job" "silver_to_gold" {
  name         = "${local.prefix}-glue-nhs-silver-to-gold"
  role_arn     = var.glue_role_arn
  description  = "Aggregates NHS Silver data into Gold Parquet"
  glue_version = "4.0"
  max_retries  = 1
  timeout      = 60

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.scripts_bucket}/scripts/glue_silver_to_gold.py"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--enable-job-insights" = "true"
    "--enable-auto-scaling" = "true"
    "--SILVER_BUCKET"       = var.silver_bucket_name
    "--GOLD_BUCKET"         = var.gold_bucket_name
    "--TempDir"             = "s3://${var.scripts_bucket}/tmp/"
  }

  worker_type       = "G.1X"
  number_of_workers = 2
}

# ---------------------------
# Glue Workflow
# Orchestrates: api_to_bronze -> crawler -> bronze_to_silver -> silver_to_gold
# ---------------------------
resource "aws_glue_workflow" "nhs_pipeline" {
  name        = "${local.prefix}-glue-nhs-workflow"
  description = "NHS prescribing pipeline: API->Bronze->Silver->Gold"
}

# Trigger 1: ON_DEMAND - triggered by Lambda
resource "aws_glue_trigger" "start_api_to_bronze" {
  name          = "${local.prefix}-trigger-start-api-to-bronze"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.nhs_pipeline.name

  actions {
    job_name = aws_glue_job.api_to_bronze.name
  }
}

# Trigger 2: Start Crawler after api_to_bronze succeeds
resource "aws_glue_trigger" "start_crawler" {
  name          = "${local.prefix}-trigger-start-crawler"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.nhs_pipeline.name

  predicate {
    conditions {
      job_name = aws_glue_job.api_to_bronze.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.bronze.name
  }
}

# Trigger 3: Start Bronze->Silver after Crawler succeeds
resource "aws_glue_trigger" "start_bronze_to_silver" {
  name          = "${local.prefix}-trigger-bronze-to-silver"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.nhs_pipeline.name

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.bronze.name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.bronze_to_silver.name
  }
}

# Trigger 4: Start Silver->Gold after Bronze->Silver succeeds
resource "aws_glue_trigger" "start_silver_to_gold" {
  name          = "${local.prefix}-trigger-silver-to-gold"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.nhs_pipeline.name

  predicate {
    conditions {
      job_name = aws_glue_job.bronze_to_silver.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.silver_to_gold.name
  }
}
