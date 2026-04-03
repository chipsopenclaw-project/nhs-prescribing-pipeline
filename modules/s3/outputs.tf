# =============================================
# modules/s3/outputs.tf
# Exports all bucket names and ARNs
# =============================================

output "bronze_bucket_name" {
  value = aws_s3_bucket.bronze.bucket
}

output "bronze_bucket_arn" {
  value = aws_s3_bucket.bronze.arn
}

output "silver_bucket_name" {
  value = aws_s3_bucket.silver.bucket
}

output "silver_bucket_arn" {
  value = aws_s3_bucket.silver.arn
}

output "gold_bucket_name" {
  value = aws_s3_bucket.gold.bucket
}

output "gold_bucket_arn" {
  value = aws_s3_bucket.gold.arn
}

output "scripts_bucket_name" {
  value = aws_s3_bucket.scripts.bucket
}

output "scripts_bucket_arn" {
  value = aws_s3_bucket.scripts.arn
}

output "athena_bucket_name" {
  value = aws_s3_bucket.athena.bucket
}

output "athena_bucket_arn" {
  value = aws_s3_bucket.athena.arn
}
