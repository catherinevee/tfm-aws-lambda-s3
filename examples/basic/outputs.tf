output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_function_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.lambda_s3_cloudwatch.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.lambda_s3_cloudwatch.s3_bucket_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.lambda_s3_cloudwatch.cloudwatch_log_group_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.lambda_s3_cloudwatch.lambda_role_arn
}

output "s3_event_notification_enabled" {
  description = "Whether S3 event notifications are enabled"
  value       = module.lambda_s3_cloudwatch.s3_event_notification_enabled
}

output "cloudwatch_alarm_names" {
  description = "Names of the CloudWatch alarms"
  value       = module.lambda_s3_cloudwatch.cloudwatch_alarm_names
} 