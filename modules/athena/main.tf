# =============================================
# modules/athena/main.tf
# Creates:
#   - Athena Workgroup (query management)
#   - Athena Database (points to Glue Catalog)
#   - Athena Named Queries (pre-built queries
#     for Streamlit to use)
# =============================================

locals {
  prefix = "ukb-${var.environment}-euw2"
}

# ---------------------------
# Athena Workgroup
# Controls query settings and cost
# ---------------------------
resource "aws_athena_workgroup" "nhs" {
  name        = "${local.prefix}-athena-nhs-workgroup"
  description = "Workgroup for NHS prescribing data queries"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_bucket_name}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    # Cost control - stop query if exceeds 1GB scanned
    bytes_scanned_cutoff_per_query = 1073741824
  }
}

# ---------------------------
# Athena Named Queries
# Pre-built queries for Streamlit dashboard
# ---------------------------

# Query 1: Top 10 drugs by total cost
resource "aws_athena_named_query" "top_drugs_by_cost" {
  name        = "top-drugs-by-cost"
  workgroup   = aws_athena_workgroup.nhs.name
  database    = var.glue_database_name
  description = "Top 10 drugs by total cost"

  query = <<-EOT
    SELECT
      bnf_name,
      SUM(total_cost)  AS total_cost,
      SUM(total_items) AS total_items
    FROM "${var.glue_database_name}"."drug_summary"
    WHERE year = YEAR(CURRENT_DATE)
    GROUP BY bnf_name
    ORDER BY total_cost DESC
    LIMIT 10;
  EOT
}

# Query 2: Monthly prescribing trend
resource "aws_athena_named_query" "monthly_trend" {
  name        = "monthly-prescribing-trend"
  workgroup   = aws_athena_workgroup.nhs.name
  database    = var.glue_database_name
  description = "Monthly prescribing trend for current year"

  query = <<-EOT
    SELECT
      month,
      SUM(total_items) AS total_items,
      SUM(total_cost)  AS total_cost
    FROM "${var.glue_database_name}"."regional_trend"
    WHERE year = YEAR(CURRENT_DATE)
    GROUP BY month
    ORDER BY month;
  EOT
}

# Query 3: Top 10 GP practices by cost
resource "aws_athena_named_query" "top_practices_by_cost" {
  name        = "top-practices-by-cost"
  workgroup   = aws_athena_workgroup.nhs.name
  database    = var.glue_database_name
  description = "Top 10 GP practices by total cost"

  query = <<-EOT
    SELECT
      practice_name,
      practice_code,
      SUM(total_cost)  AS total_cost,
      SUM(total_items) AS total_items
    FROM "${var.glue_database_name}"."practice_summary"
    WHERE year = YEAR(CURRENT_DATE)
    GROUP BY practice_name, practice_code
    ORDER BY total_cost DESC
    LIMIT 10;
  EOT
}

# Query 4: Regional comparison
resource "aws_athena_named_query" "regional_comparison" {
  name        = "regional-cost-comparison"
  workgroup   = aws_athena_workgroup.nhs.name
  database    = var.glue_database_name
  description = "Total cost comparison across regions"

  query = <<-EOT
    SELECT
      regional_office_name,
      SUM(total_cost)          AS total_cost,
      SUM(total_items)         AS total_items,
      AVG(avg_cost_per_practice) AS avg_cost_per_practice
    FROM "${var.glue_database_name}"."regional_trend"
    WHERE year = YEAR(CURRENT_DATE)
    GROUP BY regional_office_name
    ORDER BY total_cost DESC;
  EOT
}
