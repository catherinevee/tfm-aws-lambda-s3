terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Test Lambda function source code
resource "local_file" "test_lambda_function" {
  content = <<EOF
import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Test Lambda function handler
    """
    print(f"Test event received: {json.dumps(event)}")
    
    # Simple test response
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Test function executed successfully',
            'timestamp': datetime.now().isoformat(),
            'event_count': len(event.get('Records', []))
        })
    }
EOF
  filename = "${path.module}/test_lambda_function.py"
}

module "lambda_s3_cloudwatch_test" {
  source = "../"

  # Module configuration
  module_name = "test-lambda-s3"
  environment = "test"

  # Lambda function configuration
  lambda_function_name = "test-s3-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "test_lambda_function.handler"
  lambda_timeout       = 15
  lambda_memory_size   = 128
  lambda_source_path   = path.module

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "test"
    LOG_LEVEL   = "DEBUG"
  }

  # S3 bucket configuration
  s3_bucket_name = "test-lambda-s3-bucket-${random_string.test_bucket_suffix.result}"
  
  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*"]
  s3_filter_prefix             = "test/"
  s3_filter_suffix             = ".txt"

  # CloudWatch configuration
  cloudwatch_log_retention_days = 1

  # CloudWatch alarms
  cloudwatch_alarms = [
    {
      name          = "test-lambda-errors"
      description   = "Test Lambda function errors"
      metric_name   = "Errors"
      namespace     = "AWS/Lambda"
      statistic     = "Sum"
      period        = 60
      evaluation_periods = 1
      threshold     = 1
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
    }
  ]

  # Tags
  tags = {
    Project     = "test"
    Owner       = "devops"
    Environment = "test"
  }
}

# Random string for unique bucket name
resource "random_string" "test_bucket_suffix" {
  length  = 8
  special = false
  upper   = false
} 