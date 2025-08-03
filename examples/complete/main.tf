# Complete Example of Lambda S3 Integration with Monitoring and DLQ

provider "aws" {
  region = "us-west-2"
}

module "lambda_s3" {
  source = "../../"

  module_name    = "example"
  environment    = "dev"
  
  # Lambda Configuration
  lambda_function_name = "example-lambda-function"
  lambda_description  = "Example Lambda function processing S3 events"
  lambda_runtime      = "python3.11"
  lambda_handler     = "index.handler"
  lambda_timeout     = 30
  lambda_memory_size = 256
  
  lambda_environment_variables = {
    ENVIRONMENT = "dev"
    LOG_LEVEL  = "INFO"
  }

  # S3 Configuration
  s3_bucket_name            = "example-lambda-bucket-123"
  s3_bucket_force_destroy   = true
  s3_bucket_versioning     = true
  s3_bucket_encryption     = true
  s3_bucket_key_enabled    = true
  
  # Events that trigger the Lambda
  s3_events = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  s3_filter_prefix = "uploads/"
  s3_filter_suffix = ".json"

  # Dead Letter Queue Configuration
  enable_dead_letter_queue = true
  dlq_message_retention_seconds = 1209600  # 14 days
  dlq_visibility_timeout_seconds = 30
  dlq_max_message_size = 262144  # 256 KB
  
  # CloudWatch Configuration
  log_retention_days = 30
  alarm_actions     = ["arn:aws:sns:us-west-2:123456789012:example-topic"]
  duration_threshold = 10000  # 10 seconds

  tags = {
    Project     = "Example"
    CostCenter = "12345"
  }
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_s3.lambda_function_arn
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.lambda_s3.s3_bucket_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.lambda_s3.cloudwatch_log_group_name
}
