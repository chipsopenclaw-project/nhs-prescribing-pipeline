# =============================================
# modules/s3/main.tf
# Creates 5 S3 buckets:
#   - bronze  : raw CSV from Lambda
#   - silver  : cleaned Parquet
#   - gold    : aggregated Parquet
#   - scripts : Glue Job Python scripts
#   - athena  : Athena query results
# =============================================

locals {
  prefix = "ukb-${var.environment}-euw2"
}

# ---------------------------
# Bronze bucket
# ---------------------------
resource "aws_s3_bucket" "bronze" {
  bucket = "${local.prefix}-s3-nhs-bronze"
}

resource "aws_s3_bucket_versioning" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bronze" {
  bucket                  = aws_s3_bucket.bronze.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------
# Silver bucket
# ---------------------------
resource "aws_s3_bucket" "silver" {
  bucket = "${local.prefix}-s3-nhs-silver"
}

resource "aws_s3_bucket_versioning" "silver" {
  bucket = aws_s3_bucket.silver.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "silver" {
  bucket = aws_s3_bucket.silver.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "silver" {
  bucket                  = aws_s3_bucket.silver.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------
# Gold bucket
# ---------------------------
resource "aws_s3_bucket" "gold" {
  bucket = "${local.prefix}-s3-nhs-gold"
}

resource "aws_s3_bucket_versioning" "gold" {
  bucket = aws_s3_bucket.gold.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gold" {
  bucket = aws_s3_bucket.gold.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "gold" {
  bucket                  = aws_s3_bucket.gold.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------
# Scripts bucket
# ---------------------------
resource "aws_s3_bucket" "scripts" {
  bucket = "${local.prefix}-s3-nhs-scripts"
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------
# Athena results bucket
# ---------------------------
resource "aws_s3_bucket" "athena" {
  bucket = "${local.prefix}-s3-nhs-athena"
}

resource "aws_s3_bucket_public_access_block" "athena" {
  bucket                  = aws_s3_bucket.athena.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena" {
  bucket = aws_s3_bucket.athena.id

  rule {
    id     = "delete-old-query-results"
    status = "Enabled"

    filter {
      prefix = "query-results/"
    }

    expiration {
      days = 30
    }
  }
}
