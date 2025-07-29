# Local values for consistent naming and tagging
locals {
  name_prefix = "${var.module_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Module      = var.module_name
    ManagedBy   = "terraform"
  })
  
  lambda_role_name = var.lambda_role_name != null ? var.lambda_role_name : "${local.name_prefix}-lambda-role"
  dlq_name         = var.dead_letter_queue_name != null ? var.dead_letter_queue_name : "${local.name_prefix}-dlq"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = local.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda VPC execution (if VPC is configured)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count      = var.lambda_vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_custom_policy" {
  count  = var.lambda_custom_policy != null ? 1 : 0
  name   = "${local.name_prefix}-lambda-custom-policy"
  role   = aws_iam_role.lambda_role.id
  policy = var.lambda_custom_policy
}

# Additional IAM Policy ARNs attachment
resource "aws_iam_role_policy_attachment" "lambda_additional_policies" {
  for_each   = toset(var.lambda_role_policy_arns)
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = var.s3_bucket_name

  tags = local.common_tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  count  = var.s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.s3_bucket_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.s3_bucket_public_access_block.block_public_acls
  block_public_policy     = var.s3_bucket_public_access_block.block_public_policy
  ignore_public_acls      = var.s3_bucket_public_access_block.ignore_public_acls
  restrict_public_buckets = var.s3_bucket_public_access_block.restrict_public_buckets
}

# S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = length(var.s3_bucket_lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.s3_bucket_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }
}

# SQS Dead Letter Queue (if enabled)
resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = local.dlq_name

  tags = local.common_tags
}

# SQS Queue for Lambda processing (if DLQ is enabled)
resource "aws_sqs_queue" "lambda_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = "${local.name_prefix}-lambda-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue[0].arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = local.common_tags
}

# Lambda Function Source Code Archive
data "archive_file" "lambda_zip" {
  count       = var.lambda_source_path != null ? 1 : 0
  type        = "zip"
  source_dir  = var.lambda_source_path
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "main" {
  filename         = var.lambda_source_path != null ? data.archive_file.lambda_zip[0].output_path : null
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.lambda_handler
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  source_code_hash = var.lambda_source_path != null ? data.archive_file.lambda_zip[0].output_base64sha256 : var.lambda_source_code_hash

  dynamic "environment" {
    for_each = length(var.lambda_environment_variables) > 0 ? [1] : []
    content {
      variables = var.lambda_environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.lambda_vpc_config != null ? [var.lambda_vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  layers = var.lambda_layers

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_execution,
    aws_cloudwatch_log_group.lambda_logs
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = local.common_tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_alarms" {
  for_each = { for alarm in var.cloudwatch_alarms : alarm.name => alarm }

  alarm_name          = each.value.name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = local.common_tags
}

# S3 Event Notification Configuration
resource "aws_s3_bucket_notification" "lambda_notification" {
  count  = var.enable_s3_event_notification ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "lambda_function" {
    for_each = var.s3_event_types
    content {
      lambda_function_arn = aws_lambda_function.main.arn
      events              = [lambda_function.value]
      filter_prefix       = var.s3_filter_prefix
      filter_suffix       = var.s3_filter_suffix
    }
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# Lambda Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "s3_invoke" {
  count         = var.enable_s3_event_notification ? 1 : 0
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# IAM Policy for Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  count = var.enable_s3_event_notification ? 1 : 0
  name  = "${local.name_prefix}-lambda-s3-access"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for Lambda to access CloudWatch Logs
resource "aws_iam_role_policy" "lambda_cloudwatch_access" {
  name = "${local.name_prefix}-lambda-cloudwatch-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
      }
    ]
  })
}

# IAM Policy for Lambda to access SQS (if DLQ is enabled)
resource "aws_iam_role_policy" "lambda_sqs_access" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = "${local.name_prefix}-lambda-sqs-access"
  role  = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.lambda_queue[0].arn,
          aws_sqs_queue.dead_letter_queue[0].arn
        ]
      }
    ]
  })
} 