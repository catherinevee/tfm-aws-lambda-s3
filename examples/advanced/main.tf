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
  region = "us-east-1"
}

# VPC and Networking (for Lambda VPC configuration)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "lambda-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "lambda" {
  name_prefix = "lambda-sg-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-security-group"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alarms" {
  name = "lambda-cloudwatch-alarms"
}

# Example Lambda function source code with enhanced error handling
resource "local_file" "lambda_function" {
  content = <<EOF
import json
import boto3
import os
import logging
from datetime import datetime
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Enhanced Lambda function handler for S3 event processing with error handling
    """
    try:
        logger.info(f"Event received: {json.dumps(event)}")
        
        # Process S3 event
        processed_count = 0
        for record in event.get('Records', []):
            try:
                bucket = record['s3']['bucket']['name']
                key = record['s3']['object']['key']
                size = record['s3']['object']['size']
                
                logger.info(f"Processing file: s3://{bucket}/{key} (size: {size} bytes)")
                
                # Simulate processing logic
                process_s3_object(bucket, key, size)
                
                processed_count += 1
                logger.info(f"Successfully processed: s3://{bucket}/{key}")
                
            except Exception as e:
                logger.error(f"Error processing record: {e}")
                raise  # Re-raise to trigger DLQ
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'S3 event processed successfully',
                'timestamp': datetime.now().isoformat(),
                'processed_records': processed_count,
                'total_records': len(event.get('Records', []))
            })
        }
        
    except Exception as e:
        logger.error(f"Handler error: {e}")
        raise

def process_s3_object(bucket, key, size):
    """
    Process S3 object - add your business logic here
    """
    # Example: Validate file size
    if size > 100 * 1024 * 1024:  # 100MB
        raise ValueError(f"File too large: {size} bytes")
    
    # Example: Check file extension
    if not key.endswith(('.json', '.csv', '.txt')):
        raise ValueError(f"Unsupported file type: {key}")
    
    # Add your processing logic here
    # Example: Parse file, transform data, store results, etc.
    logger.info(f"Processing {key} with size {size} bytes")
    
    # Simulate processing time
    import time
    time.sleep(0.1)
EOF
  filename = "${path.module}/lambda_function.py"
}

module "lambda_s3_cloudwatch" {
  source = "../../"

  # Module configuration
  module_name = "advanced-lambda-s3"
  environment = "prod"

  # Lambda function configuration
  lambda_function_name = "advanced-s3-processor"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 60
  lambda_memory_size   = 512
  lambda_source_path   = path.module

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
    MAX_FILE_SIZE = "104857600"  # 100MB
    SUPPORTED_EXTENSIONS = ".json,.csv,.txt"
  }

  # Lambda reserved concurrency
  lambda_reserved_concurrency = 10

  # VPC configuration
  lambda_vpc_config = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  # S3 bucket configuration
  s3_bucket_name = "advanced-lambda-s3-bucket-${random_string.bucket_suffix.result}"
  
  # S3 bucket lifecycle rules
  s3_bucket_lifecycle_rules = [
    {
      id      = "delete-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    },
    {
      id      = "abort-incomplete-uploads"
      enabled = true
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]
  
  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  s3_filter_prefix             = "data/"
  s3_filter_suffix             = ""

  # CloudWatch configuration
  cloudwatch_log_retention_days = 30

  # CloudWatch alarms with SNS notifications
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
      alarm_actions = [aws_sns_topic.alarms.arn]
      ok_actions    = [aws_sns_topic.alarms.arn]
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
      threshold     = 45000
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = [aws_sns_topic.alarms.arn]
      ok_actions    = [aws_sns_topic.alarms.arn]
      insufficient_data_actions = []
    },
    {
      name          = "lambda-throttles"
      description   = "Lambda function throttles"
      metric_name   = "Throttles"
      namespace     = "AWS/Lambda"
      statistic     = "Sum"
      period        = 300
      evaluation_periods = 2
      threshold     = 1
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = [aws_sns_topic.alarms.arn]
      ok_actions    = [aws_sns_topic.alarms.arn]
      insufficient_data_actions = []
    }
  ]

  # Dead Letter Queue configuration
  enable_dead_letter_queue = true
  dead_letter_queue_name   = "lambda-dlq"
  max_receive_count        = 3

  # Custom IAM policy for additional permissions
  lambda_custom_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:DeleteObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${module.lambda_s3_cloudwatch.s3_bucket_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.alarms.arn
        ]
      }
    ]
  })

  # Tags
  tags = {
    Project     = "advanced-example"
    Owner       = "devops"
    CostCenter  = "engineering"
    Environment = "production"
    DataClassification = "internal"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
} 