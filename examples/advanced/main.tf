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

# VPC and networking resources for advanced example
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "lambda-s3-vpc"
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

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lambda-s3-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-${count.index + 1}"
  }
}

resource "aws_eip" "nat" {
  count = 2
  vpc   = true

  tags = {
    Name = "nat-eip-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
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
    Advanced Lambda function handler for S3 event processing with comprehensive error handling
    """
    logger.info(f"Event received: {json.dumps(event)}")
    
    try:
        # Process S3 event
        processed_count = 0
        for record in event.get('Records', []):
            try:
                bucket = record['s3']['bucket']['name']
                key = record['s3']['object']['key']
                size = record['s3']['object']['size']
                event_name = record['eventName']
                
                logger.info(f"Processing {event_name} for file: s3://{bucket}/{key} (size: {size} bytes)")
                
                # Add your advanced processing logic here
                # Example: Process the file, send notifications, etc.
                
                # Simulate processing time
                import time
                time.sleep(0.1)
                
                logger.info(f"Successfully processed: s3://{bucket}/{key}")
                processed_count += 1
                
            except Exception as e:
                logger.error(f"Error processing record: {e}")
                # Continue processing other records
                continue
        
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
        logger.error(f"Fatal error in handler: {e}")
        raise e
EOF
  filename = "${path.module}/lambda_function.py"
}

# KMS key for encryption
resource "aws_kms_key" "lambda" {
  description             = "KMS key for Lambda function encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "lambda-kms-key"
  }
}

resource "aws_kms_alias" "lambda" {
  name          = "alias/lambda-s3-encryption"
  target_key_id = aws_kms_key.lambda.key_id
}

# Enhanced module with comprehensive configuration
module "lambda_s3_cloudwatch" {
  source = "../../"

  # Module configuration
  module_name = "advanced-lambda-s3"
  environment = "prod"

  # Enhanced Lambda function configuration
  lambda_function_name = "advanced-s3-event-processor"
  lambda_description   = "Advanced Lambda function for S3 event processing with VPC, DLQ, and comprehensive monitoring"
  lambda_runtime       = "python3.11"
  lambda_handler       = "lambda_function.handler"
  lambda_timeout       = 300 # 5 minutes for complex processing
  lambda_memory_size   = 1024 # 1GB for memory-intensive operations
  lambda_source_path   = path.module

  # Advanced Lambda configuration
  lambda_architectures = ["x86_64"] # Can be ["arm64"] for cost optimization
  lambda_publish       = true # Enable versioning for rollbacks
  
  # Lambda KMS encryption
  lambda_kms_key_arn = aws_kms_key.lambda.arn
  
  # Lambda ephemeral storage configuration
  lambda_ephemeral_storage = {
    size = 2048 # 2GB ephemeral storage for large file processing
  }
  
  # Lambda tracing configuration
  lambda_tracing_config = {
    mode = "Active" # Enable X-Ray tracing for performance monitoring
  }
  
  # Lambda snap start configuration (for Java runtimes)
  lambda_snap_start = {
    apply_on = "PublishedVersions"
  }

  # Lambda environment variables
  lambda_environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "INFO"
    PROCESSING_TIMEOUT = "240"
    MAX_RETRIES = "5"
    BATCH_SIZE = "100"
    ENABLE_METRICS = "true"
  }

  # VPC configuration for Lambda
  lambda_vpc_config = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Enhanced S3 bucket configuration
  s3_bucket_name = "advanced-lambda-s3-bucket-${random_string.bucket_suffix.result}"
  s3_bucket_force_destroy = false # Production setting
  
  # S3 bucket versioning
  s3_bucket_versioning = true
  s3_bucket_versioning_status = "Enabled"
  
  # S3 bucket encryption with KMS
  s3_bucket_encryption = true
  s3_bucket_encryption_algorithm = "aws:kms"
  s3_bucket_kms_key_id = aws_kms_key.lambda.arn
  s3_bucket_key_enabled = true
  
  # S3 bucket public access block
  s3_bucket_public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  
  # Advanced S3 bucket lifecycle rules
  s3_bucket_lifecycle_rules = [
    {
      id      = "cleanup-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        noncurrent_days = 90
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
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        },
        {
          days          = 2555
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        },
        {
          noncurrent_days = 90
          storage_class   = "GLACIER"
        }
      ]
    }
  ]
  
  # S3 bucket CORS configuration
  s3_bucket_cors_configuration = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["https://example.com", "https://app.example.com"]
      expose_headers  = ["ETag", "x-amz-version-id"]
      max_age_seconds = 3600
    }
  ]
  
  # S3 bucket intelligent tiering
  s3_bucket_intelligent_tiering_configuration = [
    {
      id     = "entire-bucket"
      status = "Enabled"
      tiering = [
        {
          access_tier = "DEEP_ARCHIVE_ACCESS"
          days        = 180
        },
        {
          access_tier = "ARCHIVE_ACCESS"
          days        = 90
        }
      ]
    }
  ]
  
  # S3 bucket analytics configuration
  s3_bucket_analytics_configuration = [
    {
      id = "entire-bucket-analytics"
      storage_class_analysis = {
        data_export = {
          destination = {
            bucket_arn = "arn:aws:s3:::analytics-bucket"
            format     = "CSV"
            prefix     = "analytics/"
          }
        }
      }
    }
  ]

  # Enable S3 event notifications
  enable_s3_event_notification = true
  s3_event_types               = [
    "s3:ObjectCreated:*",
    "s3:ObjectRemoved:*",
    "s3:ReducedRedundancyLostObject"
  ]
  s3_filter_prefix             = "uploads/"
  s3_filter_suffix             = ".json"

  # Enhanced CloudWatch configuration
  cloudwatch_log_retention_days = 90 # Retain logs for 90 days
  cloudwatch_log_kms_key_id = aws_kms_key.lambda.arn

  # Comprehensive CloudWatch alarms
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
      threshold     = 240000 # 4 minutes
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
    },
    {
      name          = "lambda-concurrent-executions"
      description   = "Lambda concurrent executions"
      metric_name   = "ConcurrentExecutions"
      namespace     = "AWS/Lambda"
      statistic     = "Maximum"
      period        = 300
      evaluation_periods = 1
      threshold     = 100
      comparison_operator = "GreaterThanThreshold"
      alarm_actions = []
      ok_actions    = []
      insufficient_data_actions = []
      treat_missing_data = "notBreaching"
    }
  ]

  # Enhanced IAM configuration
  lambda_role_description = "Advanced IAM role for S3 processing Lambda function with VPC access"
  lambda_role_path = "/service-roles/"
  lambda_role_max_session_duration = 7200 # 2 hours
  
  # Additional IAM policies
  lambda_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
  
  # Custom IAM policy for additional permissions
  lambda_custom_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.lambda.arn
      }
    ]
  })

  # Enable dead letter queue for error handling
  enable_dead_letter_queue = true
  dead_letter_queue_name = "advanced-lambda-dlq"
  max_receive_count = 5
  
  # Enhanced SQS configuration
  sqs_dlq_delay_seconds = 0
  sqs_dlq_max_message_size = 262144
  sqs_dlq_message_retention_seconds = 1209600 # 14 days
  sqs_dlq_receive_wait_time_seconds = 20 # Long polling
  sqs_dlq_visibility_timeout_seconds = 60
  sqs_dlq_sse_enabled = true
  sqs_dlq_kms_key_id = aws_kms_key.lambda.arn
  
  sqs_lambda_delay_seconds = 0
  sqs_lambda_max_message_size = 262144
  sqs_lambda_message_retention_seconds = 1209600 # 14 days
  sqs_lambda_receive_wait_time_seconds = 20 # Long polling
  sqs_lambda_visibility_timeout_seconds = 60
  sqs_lambda_sse_enabled = true
  sqs_lambda_kms_key_id = aws_kms_key.lambda.arn

  # Tags
  tags = {
    Project     = "advanced-example"
    Owner       = "devops"
    CostCenter  = "engineering"
    Environment = "production"
    ManagedBy   = "terraform"
    DataClassification = "confidential"
    BackupRequired = "true"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Variables for the advanced example
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "advanced-lambda-s3-bucket"
} 