output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_function_name
}

output "lambda_function_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_function_invoke_arn
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

output "lambda_vpc_config" {
  description = "VPC configuration of the Lambda function"
  value       = module.lambda_s3_cloudwatch.lambda_vpc_config
}

output "sqs_dead_letter_queue_arn" {
  description = "ARN of the SQS dead letter queue"
  value       = module.lambda_s3_cloudwatch.sqs_dead_letter_queue_arn
}

output "sqs_dead_letter_queue_url" {
  description = "URL of the SQS dead letter queue"
  value       = module.lambda_s3_cloudwatch.sqs_dead_letter_queue_url
}

output "sqs_lambda_queue_arn" {
  description = "ARN of the SQS Lambda processing queue"
  value       = module.lambda_s3_cloudwatch.sqs_lambda_queue_arn
}

output "sqs_lambda_queue_url" {
  description = "URL of the SQS Lambda processing queue"
  value       = module.lambda_s3_cloudwatch.sqs_lambda_queue_url
}

output "cloudwatch_alarm_names" {
  description = "Names of the CloudWatch alarms"
  value       = module.lambda_s3_cloudwatch.cloudwatch_alarm_names
}

output "cloudwatch_alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value       = module.lambda_s3_cloudwatch.cloudwatch_alarm_arns
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alarms.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
} 