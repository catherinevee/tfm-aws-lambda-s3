# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id       = var.cloudwatch_kms_key_id

  tags = local.common_tags
}

# CloudWatch Metric Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors lambda function errors"
  alarm_actions      = var.alarm_actions
  ok_actions         = var.ok_actions

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${local.name_prefix}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "This metric monitors lambda function throttles"
  alarm_actions      = var.alarm_actions
  ok_actions         = var.ok_actions

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.name_prefix}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period             = "300"
  statistic          = "Average"
  threshold          = var.duration_threshold
  alarm_description  = "This metric monitors lambda function duration"
  alarm_actions      = var.alarm_actions
  ok_actions         = var.ok_actions

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = local.common_tags
}
