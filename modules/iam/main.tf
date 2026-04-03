# =============================================
# modules/iam/main.tf
# Creates two IAM roles:
#   - Lambda execution role
#   - Glue execution role
# =============================================

# ---------------------------
# Lambda IAM Role
# ---------------------------
resource "aws_iam_role" "lambda" {
  name = "ukb-${var.environment}-euw2-iam-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Basic Lambda logging to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to write to bronze bucket only
resource "aws_iam_role_policy" "lambda_s3" {
  name = "lambda-s3-bronze-write"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.bronze_bucket_arn,
        "${var.bronze_bucket_arn}/*"
      ]
    }]
  })
}

# Allow Lambda to trigger Glue Workflow
resource "aws_iam_role_policy" "lambda_glue" {
  name = "lambda-glue-workflow-trigger"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "glue:StartWorkflowRun",
        "glue:GetWorkflowRun",
        "glue:GetWorkflow"
      ]
      Resource = "*"
    }]
  })
}

# ---------------------------
# Glue IAM Role
# ---------------------------
resource "aws_iam_role" "glue" {
  name = "ukb-${var.environment}-euw2-iam-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Basic Glue service permissions
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Allow Glue to read/write bronze, silver, gold buckets
resource "aws_iam_role_policy" "glue_s3" {
  name = "glue-s3-medallion-access"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.bronze_bucket_arn,
        "${var.bronze_bucket_arn}/*",
        var.silver_bucket_arn,
        "${var.silver_bucket_arn}/*",
        var.gold_bucket_arn,
        "${var.gold_bucket_arn}/*",
        var.scripts_bucket_arn,
        "${var.scripts_bucket_arn}/*"
      ]
    }]
  })
}

# Allow Glue to write Athena query results
resource "aws_iam_role_policy" "glue_athena" {
  name = "glue-athena-results-access"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        var.athena_bucket_arn,
        "${var.athena_bucket_arn}/*"
      ]
    }]
  })
}
