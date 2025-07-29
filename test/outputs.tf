output "lambda_function_arn" {
  description = "ARN of the test Lambda function"
  value       = module.lambda_s3_cloudwatch_test.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the test Lambda function"
  value       = module.lambda_s3_cloudwatch_test.lambda_function_name
}

output "s3_bucket_name" {
  description = "Name of the test S3 bucket"
  value       = module.lambda_s3_cloudwatch_test.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the test S3 bucket"
  value       = module.lambda_s3_cloudwatch_test.s3_bucket_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the test CloudWatch log group"
  value       = module.lambda_s3_cloudwatch_test.cloudwatch_log_group_name
}

output "lambda_role_arn" {
  description = "ARN of the test Lambda IAM role"
  value       = module.lambda_s3_cloudwatch_test.lambda_role_arn
}

output "s3_event_notification_enabled" {
  description = "Whether S3 event notifications are enabled for test"
  value       = module.lambda_s3_cloudwatch_test.s3_event_notification_enabled
}

output "cloudwatch_alarm_names" {
  description = "Names of the test CloudWatch alarms"
  value       = module.lambda_s3_cloudwatch_test.cloudwatch_alarm_names
} 