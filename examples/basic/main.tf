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
    Enhanced Lambda function handler for S3 event processing
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

  # Enhanced Lambda function configuration
  lambda_function_name = "s3-event-processor"
  lambda_description   = "Enhanced Lambda function for S3 event processing with comprehensive configuration"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 60 # Increased timeout for processing
  lambda_memory_size   = 512 # Increased memory for better performance
  lambda_source_path   = path.module

  # Enhanced Lambda configuration
  lambda_architectures = ["x86_64"] # Can be ["arm64"] for cost optimization
  lambda_publish       = true # Enable versioning
  
  # Lambda ephemeral storage configuration
  lambda_ephemeral_storage = {
    size = 1024 # 1GB ephemeral storage
  }
  
  # Lambda tracing configuration
  lambda_tracing_config = {
    mode = "Active" # Enable X-Ray tracing
  }

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "development"
    LOG_LEVEL   = "INFO"
    PROCESSING_TIMEOUT = "30"
    MAX_RETRIES = "3"
  }

  # Enhanced S3 bucket configuration
  s3_bucket_name = "example-lambda-s3-bucket-${random_string.bucket_suffix.result}"
  s3_bucket_force_destroy = true # For testing purposes
  
  # S3 bucket versioning
  s3_bucket_versioning = true
  s3_bucket_versioning_status = "Enabled"
  
  # S3 bucket encryption
  s3_bucket_encryption = true
  s3_bucket_encryption_algorithm = "AES256"
  s3_bucket_key_enabled = true
  
  # S3 bucket public access block
  s3_bucket_public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  
  # S3 bucket lifecycle rules
  s3_bucket_lifecycle_rules = [
    {
      id      = "cleanup-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    },
    {
      id      = "transition-to-ia"
      enabled = true
      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
    }
  ]
  
  # S3 bucket CORS configuration
  s3_bucket_cors_configuration = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE"]
      allowed_origins = ["https://example.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  s3_filter_prefix             = "uploads/"
  s3_filter_suffix             = ".json"

  # Enhanced CloudWatch configuration
  cloudwatch_log_retention_days = 30 # Retain logs for 30 days

  # Enhanced CloudWatch alarms
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
      treat_missing_data = "notBreaching"
    },
    {
      name          = "lambda-duration"
      description   = "Lambda function duration"
      metric_name   = "Duration"
      namespace     = "AWS/Lambda"
      statistic     = "Average"
      period        = 300
      evaluation_periods = 2
      threshold     = 50000 # 50 seconds
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
      treat_missing_data = "notBreaching"
    },
    {
      name          = "lambda-throttles"
      description   = "Lambda function throttles"
      metric_name   = "Throttles"
      namespace     = "AWS/Lambda"
      statistic     = "Sum"
      period        = 300
      evaluation_periods = 1
      threshold     = 1
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
      treat_missing_data = "notBreaching"
    }
  ]

  # Enhanced IAM configuration
  lambda_role_description = "Enhanced IAM role for S3 processing Lambda function"
  lambda_role_path = "/service-roles/"
  lambda_role_max_session_duration = 7200 # 2 hours
  
  # Additional IAM policies
  lambda_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  # Tags
  tags = {
    Project     = "example"
    Owner       = "devops"
    CostCenter  = "engineering"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
} 