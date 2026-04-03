# =============================================
# modules/lambda/outputs.tf
# Exports Lambda ARN and name
# for EventBridge module to reference
# =============================================

output "lambda_arn" {
  description = "ARN of the NHS fetcher Lambda function"
  value       = aws_lambda_function.nhs_fetcher.arn
}

output "lambda_func_name" {
  description = "Name of the NHS fetcher Lambda function"
  value       = aws_lambda_function.nhs_fetcher.function_name
}
