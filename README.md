# Enhanced AWS Lambda S3 CloudWatch Module

A comprehensive Terraform module for deploying AWS Lambda functions with S3 event triggers, CloudWatch monitoring, and extensive customization options.

## Features

- **Lambda Function**: Fully configurable Lambda function with support for all AWS Lambda features
- **S3 Bucket**: Comprehensive S3 bucket configuration with advanced features
- **CloudWatch Monitoring**: Built-in CloudWatch logs and alarms
- **Dead Letter Queue**: Optional SQS-based error handling
- **VPC Support**: Lambda VPC configuration for enhanced security
- **IAM Integration**: Comprehensive IAM roles and policies
- **Encryption**: KMS encryption support for all resources
- **Event Notifications**: S3 event triggers with filtering

## Enhanced Customizable Parameters

### Lambda Function Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lambda_function_name` | string | - | Name of the Lambda function |
| `lambda_description` | string | "Lambda function for S3 processing" | Description of the Lambda function |
| `lambda_runtime` | string | "python3.11" | Lambda function runtime |
| `lambda_handler` | string | "index.handler" | Lambda function handler |
| `lambda_timeout` | number | 30 | Lambda function timeout in seconds (1-900) |
| `lambda_memory_size` | number | 128 | Lambda function memory size in MB (128-10240) |
| `lambda_architectures` | list(string) | ["x86_64"] | Lambda function architectures (x86_64, arm64) |
| `lambda_publish` | bool | false | Whether to publish Lambda versions |
| `lambda_kms_key_arn` | string | null | KMS key ARN for Lambda encryption |
| `lambda_ephemeral_storage` | object | {size = 512} | Ephemeral storage configuration (512-10240 MB) |
| `lambda_tracing_config` | object | {mode = "PassThrough"} | X-Ray tracing configuration |
| `lambda_snap_start` | object | null | Snap start configuration for Java runtimes |
| `lambda_code_signing_config_arn` | string | null | Code signing configuration ARN |
| `lambda_package_type` | string | "Zip" | Package type (Zip, Image) |
| `lambda_image_uri` | string | null | ECR image URI for container images |
| `lambda_reserved_concurrency` | number | null | Reserved concurrency limit |
| `lambda_layers` | list(string) | [] | Lambda layer ARNs |
| `lambda_environment_variables` | map(string) | {} | Environment variables |
| `lambda_source_path` | string | null | Path to Lambda source code |
| `lambda_source_code_hash` | string | null | Source code hash for external deployments |

### IAM Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lambda_role_name` | string | null | IAM role name (auto-generated if null) |
| `lambda_role_description` | string | "IAM role for Lambda function" | IAM role description |
| `lambda_role_path` | string | "/" | IAM role path |
| `lambda_role_permissions_boundary` | string | null | Permissions boundary ARN |
| `lambda_role_max_session_duration` | number | 3600 | Maximum session duration (3600-43200) |
| `lambda_role_policy_arns` | list(string) | [] | Additional IAM policy ARNs |
| `lambda_custom_policy` | string | null | Custom IAM policy document |
| `lambda_role_tags` | map(string) | {} | Additional IAM role tags |

### VPC Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lambda_vpc_config` | object | null | VPC configuration with subnet_ids and security_group_ids |

### S3 Bucket Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `s3_bucket_name` | string | - | S3 bucket name |
| `s3_bucket_force_destroy` | bool | false | Force destroy bucket even with objects |
| `s3_bucket_versioning` | bool | false | Enable bucket versioning |
| `s3_bucket_versioning_status` | string | "Enabled" | Versioning status |
| `s3_bucket_encryption` | bool | true | Enable server-side encryption |
| `s3_bucket_encryption_algorithm` | string | "AES256" | Encryption algorithm (AES256, aws:kms) |
| `s3_bucket_kms_key_id` | string | null | KMS key for encryption |
| `s3_bucket_key_enabled` | bool | true | Enable bucket key |
| `s3_bucket_public_access_block` | object | {block_public_acls = true, ...} | Public access block settings |
| `s3_bucket_lifecycle_rules` | list(object) | [] | Lifecycle rules configuration |
| `s3_bucket_cors_configuration` | list(object) | [] | CORS configuration |
| `s3_bucket_website_configuration` | object | null | Website configuration |
| `s3_bucket_object_lock_configuration` | object | null | Object lock configuration |
| `s3_bucket_replication_configuration` | object | null | Replication configuration |
| `s3_bucket_intelligent_tiering_configuration` | list(object) | [] | Intelligent tiering |
| `s3_bucket_analytics_configuration` | list(object) | [] | Analytics configuration |
| `s3_bucket_inventory_configuration` | list(object) | [] | Inventory configuration |
| `s3_bucket_metric_configuration` | list(object) | [] | Metric configuration |
| `s3_bucket_ownership_controls` | object | null | Ownership controls |
| `s3_bucket_request_payer` | string | null | Request payer configuration |
| `s3_bucket_accelerate_configuration` | object | null | Transfer acceleration |
| `s3_bucket_policy` | string | null | Custom bucket policy |
| `s3_bucket_tags` | map(string) | {} | Additional bucket tags |

### SQS Configuration (Dead Letter Queue)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_dead_letter_queue` | bool | false | Enable SQS dead letter queue |
| `dead_letter_queue_name` | string | null | DLQ name (auto-generated if null) |
| `max_receive_count` | number | 3 | Max receive count before DLQ |
| `sqs_dlq_delay_seconds` | number | 0 | DLQ delay seconds (0-900) |
| `sqs_dlq_max_message_size` | number | 262144 | DLQ max message size (1024-262144) |
| `sqs_dlq_message_retention_seconds` | number | 345600 | DLQ message retention (60-1209600) |
| `sqs_dlq_receive_wait_time_seconds` | number | 0 | DLQ receive wait time (0-20) |
| `sqs_dlq_visibility_timeout_seconds` | number | 30 | DLQ visibility timeout (0-43200) |
| `sqs_dlq_sse_enabled` | bool | true | DLQ server-side encryption |
| `sqs_dlq_kms_key_id` | string | null | DLQ KMS key |
| `sqs_lambda_delay_seconds` | number | 0 | Lambda queue delay seconds |
| `sqs_lambda_max_message_size` | number | 262144 | Lambda queue max message size |
| `sqs_lambda_message_retention_seconds` | number | 345600 | Lambda queue message retention |
| `sqs_lambda_receive_wait_time_seconds` | number | 0 | Lambda queue receive wait time |
| `sqs_lambda_visibility_timeout_seconds` | number | 30 | Lambda queue visibility timeout |
| `sqs_lambda_sse_enabled` | bool | true | Lambda queue server-side encryption |
| `sqs_lambda_kms_key_id` | string | null | Lambda queue KMS key |

### CloudWatch Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cloudwatch_log_retention_days` | number | 7 | Log retention days |
| `cloudwatch_log_kms_key_id` | string | null | Log group KMS key |
| `cloudwatch_alarms` | list(object) | [] | CloudWatch alarms configuration |

### S3 Event Notifications

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_s3_event_notification` | bool | false | Enable S3 event notifications |
| `s3_event_types` | list(string) | ["s3:ObjectCreated:*"] | S3 event types |
| `s3_filter_prefix` | string | null | Event filter prefix |
| `s3_filter_suffix` | string | null | Event filter suffix |

## Usage Examples

### Basic Example

```hcl
module "lambda_s3_basic" {
  source = "./tfm-aws-lambda-s3"

  module_name = "basic-lambda-s3"
  environment = "dev"

  lambda_function_name = "s3-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "index.handler"
  lambda_source_path   = "./lambda"

  s3_bucket_name = "my-lambda-bucket"

  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*"]

  tags = {
    Project = "example"
    Owner   = "devops"
  }
}
```

### Advanced Example with VPC and DLQ

```hcl
module "lambda_s3_advanced" {
  source = "./tfm-aws-lambda-s3"

  module_name = "advanced-lambda-s3"
  environment = "prod"

  # Enhanced Lambda configuration
  lambda_function_name = "advanced-s3-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "index.handler"
  lambda_timeout       = 300
  lambda_memory_size   = 1024
  lambda_architectures = ["x86_64"]
  lambda_publish       = true

  # VPC configuration
  lambda_vpc_config = {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  # S3 configuration
  s3_bucket_name = "advanced-lambda-bucket"
  s3_bucket_versioning = true
  s3_bucket_encryption = true
  s3_bucket_kms_key_id = var.kms_key_arn

  # Dead letter queue
  enable_dead_letter_queue = true
  max_receive_count = 5

  # CloudWatch monitoring
  cloudwatch_log_retention_days = 90
  cloudwatch_alarms = [
    {
      name          = "lambda-errors"
      description   = "Lambda function errors"
      metric_name   = "Errors"
      namespace     = "AWS/Lambda"
      statistic     = "Sum"
      period        = 300
      evaluation_periods = 2
      threshold     = 1
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
    }
  ]

  tags = {
    Project     = "advanced"
    Environment = "production"
    DataClassification = "confidential"
  }
}
```

## Outputs

The module provides comprehensive outputs for all created resources:

- Lambda function ARN, name, and configuration
- IAM role ARN and name
- S3 bucket ID, ARN, and domain names
- CloudWatch log group ARN and name
- SQS queue ARNs and URLs (if DLQ enabled)
- CloudWatch alarm ARNs and names
- Module information and tags

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS account with appropriate permissions

## Contributing

This module is designed to be highly customizable while maintaining security best practices. All parameters include validation and sensible defaults.