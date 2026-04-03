# =============================================
# modules/iam/outputs.tf
# =============================================

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "glue_role_arn" {
  description = "ARN of the Glue execution role"
  value       = aws_iam_role.glue.arn
}
