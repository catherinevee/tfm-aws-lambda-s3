# Lambda Function Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = aws_lambda_function.main.invoke_arn
}

output "lambda_function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.main.version
}

output "lambda_function_last_modified" {
  description = "Date the Lambda function was last modified"
  value       = aws_lambda_function.main.last_modified
}

# IAM Role Outputs
output "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_role.name
}

# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.main.region
}

output "s3_bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

# CloudWatch Log Group Outputs
output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

# SQS Queue Outputs (if DLQ is enabled)
output "sqs_dead_letter_queue_arn" {
  description = "ARN of the SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].arn : null
}

output "sqs_dead_letter_queue_url" {
  description = "URL of the SQS dead letter queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.dead_letter_queue[0].url : null
}

output "sqs_lambda_queue_arn" {
  description = "ARN of the SQS Lambda processing queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.lambda_queue[0].arn : null
}

output "sqs_lambda_queue_url" {
  description = "URL of the SQS Lambda processing queue"
  value       = var.enable_dead_letter_queue ? aws_sqs_queue.lambda_queue[0].url : null
}

# CloudWatch Alarms Outputs
output "cloudwatch_alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.lambda_alarms : alarm.arn]
}

output "cloudwatch_alarm_names" {
  description = "Names of the CloudWatch alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.lambda_alarms : alarm.alarm_name]
}

# Module Information Outputs
output "module_name" {
  description = "Name of the module"
  value       = var.module_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "tags" {
  description = "Tags applied to all resources"
  value       = local.common_tags
}

# Lambda Function Configuration Outputs
output "lambda_runtime" {
  description = "Runtime of the Lambda function"
  value       = aws_lambda_function.main.runtime
}

output "lambda_handler" {
  description = "Handler of the Lambda function"
  value       = aws_lambda_function.main.handler
}

output "lambda_timeout" {
  description = "Timeout of the Lambda function"
  value       = aws_lambda_function.main.timeout
}

output "lambda_memory_size" {
  description = "Memory size of the Lambda function"
  value       = aws_lambda_function.main.memory_size
}

output "lambda_environment_variables" {
  description = "Environment variables of the Lambda function"
  value       = aws_lambda_function.main.environment
  sensitive   = true
}

# S3 Event Notification Outputs
output "s3_event_notification_enabled" {
  description = "Whether S3 event notifications are enabled"
  value       = var.enable_s3_event_notification
}

output "s3_event_types" {
  description = "S3 event types configured for Lambda triggers"
  value       = var.enable_s3_event_notification ? var.s3_event_types : []
}

# VPC Configuration Outputs (if configured)
output "lambda_vpc_config" {
  description = "VPC configuration of the Lambda function"
  value       = aws_lambda_function.main.vpc_config
}

# Lambda Layers Outputs
output "lambda_layers" {
  description = "Lambda layers attached to the function"
  value       = aws_lambda_function.main.layers
}

# Reserved Concurrency Outputs
output "lambda_reserved_concurrency" {
  description = "Reserved concurrency limit of the Lambda function"
  value       = aws_lambda_function.main.reserved_concurrent_executions
} 