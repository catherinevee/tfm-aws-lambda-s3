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

# Example Lambda function source code
resource "local_file" "lambda_function" {
  content = <<EOF
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
EOF
  filename = "${path.module}/lambda_function.py"
}

module "lambda_s3_cloudwatch" {
  source = "../../"

  # Module configuration
  module_name = "example-lambda-s3"
  environment = "dev"

  # Lambda function configuration
  lambda_function_name = "s3-event-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 30
  lambda_memory_size   = 256
  lambda_source_path   = path.module

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "development"
    LOG_LEVEL   = "INFO"
  }

  # S3 bucket configuration
  s3_bucket_name = "example-lambda-s3-bucket-${random_string.bucket_suffix.result}"
  
  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*"]
  s3_filter_prefix             = "uploads/"
  s3_filter_suffix             = ".json"

  # CloudWatch configuration
  cloudwatch_log_retention_days = 7

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
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
    },
    {
      name          = "lambda-duration"
      description   = "Lambda function duration"
      metric_name   = "Duration"
      namespace     = "AWS/Lambda"
      statistic     = "Average"
      period        = 300
      evaluation_periods = 2
      threshold     = 25000
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
    }
  ]

  # Tags
  tags = {
    Project     = "example"
    Owner       = "devops"
    CostCenter  = "engineering"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
} 