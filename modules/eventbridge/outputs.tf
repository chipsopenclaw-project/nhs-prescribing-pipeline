# =============================================
# modules/eventbridge/outputs.tf
# =============================================

output "event_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.monthly_trigger.arn
}

output "event_rule_name" {
  description = "Name of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.monthly_trigger.name
}
