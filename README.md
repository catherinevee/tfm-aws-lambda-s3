# AWS Lambda + S3 + CloudWatch Terraform Module

A comprehensive Terraform module for deploying AWS Lambda functions with S3 event triggers and CloudWatch monitoring. This module provides a complete serverless solution for processing S3 events with built-in monitoring, error handling, and scalability features.

## Features

- **Lambda Function**: Deploy serverless functions with configurable runtime, memory, and timeout
- **S3 Integration**: Automatic S3 bucket creation with event notifications to trigger Lambda
- **CloudWatch Monitoring**: Comprehensive logging and customizable alarms
- **IAM Security**: Secure IAM roles and policies following least privilege principle
- **VPC Support**: Optional VPC configuration for Lambda functions
- **Dead Letter Queue**: SQS-based error handling for failed executions
- **Lifecycle Management**: S3 bucket lifecycle rules for cost optimization
- **Event Filtering**: Configurable S3 event filters (prefix/suffix)
- **Reserved Concurrency**: Control Lambda function scaling
- **Custom Policies**: Extensible IAM policies for additional permissions

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 Bucket     │───▶│  Lambda Function│───▶│  CloudWatch     │
│                 │    │                 │    │  Logs/Alarms    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 Events     │    │   IAM Role      │    │   SNS Topic     │
│   (Optional)    │    │   & Policies    │    │   (Optional)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   SQS DLQ       │    │   VPC Config    │
│   (Optional)    │    │   (Optional)    │
└─────────────────┘    └─────────────────┘
```

## Usage

### Basic Example

```hcl
module "lambda_s3_cloudwatch" {
  source = "./tfm-aws-lambda-s3"

  # Module configuration
  module_name = "my-lambda-s3"
  environment = "dev"

  # Lambda function configuration
  lambda_function_name = "s3-event-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 30
  lambda_memory_size   = 256
  lambda_source_path   = "./lambda"

  # S3 bucket configuration
  s3_bucket_name = "my-lambda-s3-bucket"

  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*"]
  s3_filter_prefix             = "uploads/"
  s3_filter_suffix             = ".json"

  # CloudWatch configuration
  cloudwatch_log_retention_days = 7

  # Tags
  tags = {
    Project     = "my-project"
    Owner       = "devops"
    Environment = "development"
  }
}
```

### Advanced Example with VPC and Dead Letter Queue

```hcl
module "lambda_s3_cloudwatch" {
  source = "./tfm-aws-lambda-s3"

  # Module configuration
  module_name = "advanced-lambda-s3"
  environment = "prod"

  # Lambda function configuration
  lambda_function_name = "advanced-s3-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 60
  lambda_memory_size   = 512
  lambda_source_path   = "./lambda"

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
  }

  # Lambda reserved concurrency
  lambda_reserved_concurrency = 10

  # VPC configuration
  lambda_vpc_config = {
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    security_group_ids = ["sg-12345678"]
  }

  # S3 bucket configuration
  s3_bucket_name = "advanced-lambda-s3-bucket"

  # S3 bucket lifecycle rules
  s3_bucket_lifecycle_rules = [
    {
      id      = "delete-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]

  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  # CloudWatch configuration
  cloudwatch_log_retention_days = 30

  # CloudWatch alarms
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
      alarm_actions = ["arn:aws:sns:region:account:topic-name"]
      ok_actions    = ["arn:aws:sns:region:account:topic-name"]
      insufficient_data_actions = []
    }
  ]

  # Dead Letter Queue configuration
  enable_dead_letter_queue = true
  dead_letter_queue_name   = "lambda-dlq"
  max_receive_count        = 3

  # Tags
  tags = {
    Project     = "advanced-project"
    Owner       = "devops"
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |
| archive | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| archive | ~> 2.0 |

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a |
| lambda_function_name | Name of the Lambda function | `string` | n/a |
| s3_bucket_name | Name of the S3 bucket | `string` | n/a |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| module_name | Name of the module | `string` | `"lambda-s3-cloudwatch"` |
| tags | A map of tags to assign to all resources | `map(string)` | `{}` |
| lambda_runtime | Lambda function runtime | `string` | `"python3.11"` |
| lambda_handler | Lambda function handler | `string` | `"index.handler"` |
| lambda_timeout | Lambda function timeout in seconds | `number` | `30` |
| lambda_memory_size | Lambda function memory size in MB | `number` | `128` |
| lambda_source_path | Path to the Lambda function source code | `string` | `null` |
| lambda_environment_variables | Environment variables for the Lambda function | `map(string)` | `{}` |
| lambda_reserved_concurrency | Reserved concurrency limit for the Lambda function | `number` | `null` |
| lambda_layers | List of Lambda layer ARNs to attach to the function | `list(string)` | `[]` |
| s3_bucket_versioning | Enable versioning for the S3 bucket | `bool` | `true` |
| s3_bucket_encryption | Enable server-side encryption for the S3 bucket | `bool` | `true` |
| s3_bucket_public_access_block | Public access block configuration for the S3 bucket | `object` | See variables.tf |
| s3_bucket_lifecycle_rules | Lifecycle rules for the S3 bucket | `list(object)` | `[]` |
| cloudwatch_log_retention_days | Number of days to retain CloudWatch logs | `number` | `14` |
| cloudwatch_alarms | CloudWatch alarms configuration | `list(object)` | `[]` |
| lambda_role_name | Name of the IAM role for the Lambda function | `string` | `null` |
| lambda_role_policy_arns | List of IAM policy ARNs to attach to the Lambda role | `list(string)` | `[]` |
| lambda_custom_policy | Custom IAM policy JSON for the Lambda function | `string` | `null` |
| enable_s3_event_notification | Enable S3 event notifications to trigger Lambda | `bool` | `false` |
| s3_event_types | List of S3 event types to trigger Lambda | `list(string)` | `["s3:ObjectCreated:*"]` |
| s3_filter_prefix | S3 object key prefix filter for event notifications | `string` | `""` |
| s3_filter_suffix | S3 object key suffix filter for event notifications | `string` | `""` |
| lambda_vpc_config | VPC configuration for Lambda function | `object` | `null` |
| enable_dead_letter_queue | Enable SQS dead letter queue for failed Lambda executions | `bool` | `false` |
| dead_letter_queue_name | Name of the SQS dead letter queue | `string` | `null` |
| max_receive_count | Maximum number of times a message can be received before being sent to the dead letter queue | `number` | `3` |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | ARN of the Lambda function |
| lambda_function_name | Name of the Lambda function |
| lambda_function_invoke_arn | Invocation ARN of the Lambda function |
| lambda_function_version | Latest published version of the Lambda function |
| lambda_function_last_modified | Date the Lambda function was last modified |
| lambda_role_arn | ARN of the IAM role for the Lambda function |
| lambda_role_name | Name of the IAM role for the Lambda function |
| s3_bucket_id | The name of the S3 bucket |
| s3_bucket_arn | The ARN of the S3 bucket |
| s3_bucket_region | The AWS region this bucket resides in |
| s3_bucket_domain_name | The bucket domain name |
| s3_bucket_regional_domain_name | The bucket region-specific domain name |
| cloudwatch_log_group_arn | ARN of the CloudWatch log group |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
| sqs_dead_letter_queue_arn | ARN of the SQS dead letter queue |
| sqs_dead_letter_queue_url | URL of the SQS dead letter queue |
| sqs_lambda_queue_arn | ARN of the SQS Lambda processing queue |
| sqs_lambda_queue_url | URL of the SQS Lambda processing queue |
| cloudwatch_alarm_arns | ARNs of the CloudWatch alarms |
| cloudwatch_alarm_names | Names of the CloudWatch alarms |
| module_name | Name of the module |
| environment | Environment name |
| tags | Tags applied to all resources |

## Examples

### Basic Example
See `examples/basic/` for a simple implementation with S3 event notifications.

### Advanced Example
See `examples/advanced/` for a comprehensive implementation with VPC, dead letter queue, and enhanced monitoring.

### Test Example
See `test/` for a minimal test configuration.

## Lambda Function Examples

### Python Example
```python
import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Lambda function handler for S3 event processing
    """
    print(f"Event received: {json.dumps(event)}")
    
    # Process S3 event
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        size = record['s3']['object']['size']
        
        print(f"Processing file: s3://{bucket}/{key} (size: {size} bytes)")
        
        # Add your processing logic here
        # Example: Process the file, send notifications, etc.
        
        # Log processing completion
        print(f"Successfully processed: s3://{bucket}/{key}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'S3 event processed successfully',
            'timestamp': datetime.now().isoformat(),
            'processed_records': len(event.get('Records', []))
        })
    }
```

### Node.js Example
```javascript
const AWS = require('aws-sdk');

exports.handler = async (event, context) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    // Process S3 event
    for (const record of event.Records || []) {
        const bucket = record.s3.bucket.name;
        const key = record.s3.object.key;
        const size = record.s3.object.size;
        
        console.log(`Processing file: s3://${bucket}/${key} (size: ${size} bytes)`);
        
        // Add your processing logic here
        // Example: Process the file, send notifications, etc.
        
        console.log(`Successfully processed: s3://${bucket}/${key}`);
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'S3 event processed successfully',
            timestamp: new Date().toISOString(),
            processedRecords: event.Records ? event.Records.length : 0
        })
    };
};
```

## Security Features

- **IAM Least Privilege**: Minimal required permissions for Lambda function
- **S3 Security**: Public access blocked by default, server-side encryption enabled
- **VPC Isolation**: Optional VPC configuration for network isolation
- **Dead Letter Queue**: Error handling for failed executions
- **CloudWatch Monitoring**: Comprehensive logging and alerting

## Best Practices

1. **Environment Separation**: Use different module instances for dev, staging, and prod
2. **Resource Naming**: Use consistent naming conventions with environment prefixes
3. **Tagging**: Apply comprehensive tags for cost tracking and resource management
4. **Monitoring**: Configure CloudWatch alarms for critical metrics
5. **Error Handling**: Implement proper error handling in Lambda functions
6. **Security**: Review and customize IAM policies based on your requirements
7. **Testing**: Use the test configuration to validate deployments
8. **Backup**: Enable S3 versioning for data protection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Check the examples directory
2. Review the variables and outputs documentation
3. Open an issue on GitHub

## Changelog

### Version 1.0.0
- Initial release
- Basic Lambda + S3 + CloudWatch integration
- Support for VPC configuration
- Dead letter queue functionality
- Comprehensive monitoring and alerting