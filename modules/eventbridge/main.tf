# =============================================
# modules/eventbridge/main.tf
# Creates scheduled EventBridge rule that
# triggers Lambda on a monthly schedule
# =============================================

locals {
  prefix = "ukb-${var.environment}-euw2"
}

# Defines when to trigger
resource "aws_cloudwatch_event_rule" "monthly_trigger" {
  name                = "${local.prefix}-eventbridge-nhs-schedule"
  description         = "Triggers NHS prescribing pipeline monthly"
  schedule_expression = var.lambda_schedule
  state               = "ENABLED"
}

# Defines what to trigger
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_trigger.name
  target_id = "NHSPrescribingLambda"
  arn       = var.lambda_arn
}

# Allows EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_func_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_trigger.arn
}
