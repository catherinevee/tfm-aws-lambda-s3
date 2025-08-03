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
  description = var.lambda_role_description # Default: "IAM role for Lambda function"
  path = var.lambda_role_path # Default: "/"
  permissions_boundary = var.lambda_role_permissions_boundary # Default: null
  max_session_duration = var.lambda_role_max_session_duration # Default: 3600 seconds (1 hour)

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

  tags = merge(local.common_tags, var.lambda_role_tags) # Additional role-specific tags
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
  force_destroy = var.s3_bucket_force_destroy # Default: false

  tags = merge(local.common_tags, var.s3_bucket_tags) # Additional bucket-specific tags
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  count  = var.s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.s3_bucket_versioning_status # Default: "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.s3_bucket_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.s3_bucket_encryption_algorithm # Default: "AES256"
      kms_master_key_id = var.s3_bucket_kms_key_id # Default: null
    }
    bucket_key_enabled = var.s3_bucket_key_enabled # Default: true
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.s3_bucket_public_access_block.block_public_acls # Default: true
  block_public_policy     = var.s3_bucket_public_access_block.block_public_policy # Default: true
  ignore_public_acls      = var.s3_bucket_public_access_block.ignore_public_acls # Default: true
  restrict_public_buckets = var.s3_bucket_public_access_block.restrict_public_buckets # Default: true
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "main" {
  count  = length(var.s3_bucket_cors_configuration) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "cors_rule" {
    for_each = var.s3_bucket_cors_configuration
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "main" {
  count  = var.s3_bucket_website_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = var.s3_bucket_website_configuration.index_document
  }

  dynamic "error_document" {
    for_each = var.s3_bucket_website_configuration.error_document != null ? [var.s3_bucket_website_configuration.error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.s3_bucket_website_configuration.redirect_all_requests_to != null ? [var.s3_bucket_website_configuration.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value
    }
  }

  routing_rules = var.s3_bucket_website_configuration.routing_rules # Default: null
}

# S3 Bucket Object Lock Configuration
resource "aws_s3_bucket_object_lock_configuration" "main" {
  count  = var.s3_bucket_object_lock_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  object_lock_enabled = var.s3_bucket_object_lock_configuration.object_lock_enabled

  dynamic "rule" {
    for_each = var.s3_bucket_object_lock_configuration.rule != null ? [var.s3_bucket_object_lock_configuration.rule] : []
    content {
      default_retention {
        mode  = rule.value.default_retention.mode
        days  = rule.value.default_retention.days # Default: null
        years = rule.value.default_retention.years # Default: null
      }
    }
  }
}

# S3 Bucket Replication Configuration
resource "aws_s3_bucket_replication_configuration" "main" {
  count  = var.s3_bucket_replication_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  role   = var.s3_bucket_replication_configuration.role

  dynamic "rule" {
    for_each = var.s3_bucket_replication_configuration.rules
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority # Default: null

      destination {
        bucket             = rule.value.destination.bucket
        storage_class      = rule.value.destination.storage_class # Default: null
        replica_kms_key_id = rule.value.destination.replica_kms_key_id # Default: null
        account            = rule.value.destination.account # Default: null

        dynamic "access_control_translation" {
          for_each = rule.value.destination.access_control_translation != null ? [rule.value.destination.access_control_translation] : []
          content {
            owner = access_control_translation.value.owner
          }
        }

        dynamic "metrics" {
          for_each = rule.value.destination.metrics != null ? [rule.value.destination.metrics] : []
          content {
            status = metrics.value.status
            dynamic "event_threshold" {
              for_each = metrics.value.event_threshold != null ? [metrics.value.event_threshold] : []
              content {
                minutes = event_threshold.value.minutes
              }
            }
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria != null ? [rule.value.source_selection_criteria] : []
        content {
          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects != null ? [source_selection_criteria.value.sse_kms_encrypted_objects] : []
            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
        }
      }

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          prefix = filter.value.prefix # Default: null
          tags   = filter.value.tags # Default: empty map
        }
      }
    }
  }
}

# S3 Bucket Intelligent Tiering Configuration
resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  for_each = { for config in var.s3_bucket_intelligent_tiering_configuration : config.id => config }
  bucket   = aws_s3_bucket.main.id
  name     = each.value.id
  status   = each.value.status

  dynamic "tiering" {
    for_each = each.value.tiering
    content {
      access_tier = tiering.value.access_tier
      days        = tiering.value.days
    }
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix # Default: null
      tags   = filter.value.tags # Default: empty map
    }
  }
}

# S3 Bucket Analytics Configuration
resource "aws_s3_bucket_analytics_configuration" "main" {
  for_each = { for config in var.s3_bucket_analytics_configuration : config.id => config }
  bucket   = aws_s3_bucket.main.id
  name     = each.value.id

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix # Default: null
      tags   = filter.value.tags # Default: empty map
    }
  }

  storage_class_analysis {
    dynamic "data_export" {
      for_each = each.value.storage_class_analysis.data_export != null ? [each.value.storage_class_analysis.data_export] : []
      content {
        destination {
          bucket_arn = data_export.value.destination.bucket_arn
          format     = data_export.value.destination.format
          prefix     = data_export.value.destination.prefix # Default: null
        }
      }
    }
  }
}

# S3 Bucket Inventory Configuration
resource "aws_s3_bucket_inventory" "main" {
  for_each = { for config in var.s3_bucket_inventory_configuration : config.id => config }
  bucket   = aws_s3_bucket.main.id
  name     = each.value.id

  destination {
    bucket {
      format     = each.value.destination.bucket.format
      bucket_arn = each.value.destination.bucket.bucket_arn
      account_id = each.value.destination.bucket.account_id # Default: null
      prefix     = each.value.destination.bucket.prefix # Default: null

      dynamic "encryption" {
        for_each = each.value.destination.bucket.encryption != null ? [each.value.destination.bucket.encryption] : []
        content {
          dynamic "sse_kms" {
            for_each = encryption.value.sse_kms != null ? [encryption.value.sse_kms] : []
            content {
              key_id = sse_kms.value.key_id
            }
          }
          sse_s3 = encryption.value.sse_s3 # Default: null
        }
      }
    }
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix # Default: null
    }
  }

  included_object_versions = each.value.included_object_versions
  optional_fields          = each.value.optional_fields # Default: empty list

  schedule {
    frequency = each.value.schedule.frequency
  }
}

# S3 Bucket Metric Configuration
resource "aws_s3_bucket_metric" "main" {
  for_each = { for config in var.s3_bucket_metric_configuration : config.id => config }
  bucket   = aws_s3_bucket.main.id
  name     = each.value.id

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix # Default: null
      tags   = filter.value.tags # Default: empty map
    }
  }
}

# S3 Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "main" {
  count  = var.s3_bucket_ownership_controls != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = var.s3_bucket_ownership_controls.rule.object_ownership
  }
}

# S3 Bucket Request Payer Configuration
resource "aws_s3_bucket_request_payment_configuration" "main" {
  count  = var.s3_bucket_request_payer != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  payer  = var.s3_bucket_request_payer
}

# S3 Bucket Accelerate Configuration
resource "aws_s3_bucket_accelerate_configuration" "main" {
  count  = var.s3_bucket_accelerate_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  status = var.s3_bucket_accelerate_configuration.status
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

      dynamic "transition" {
        for_each = rule.value.transition
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transition
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# SQS Dead Letter Queue (if enabled)
resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = local.dlq_name

  # Enhanced SQS configuration
  delay_seconds = var.sqs_dlq_delay_seconds # Default: 0
  max_message_size = var.sqs_dlq_max_message_size # Default: 262144 (256 KB)
  message_retention_seconds = var.sqs_dlq_message_retention_seconds # Default: 345600 (4 days)
  receive_wait_time_seconds = var.sqs_dlq_receive_wait_time_seconds # Default: 0
  visibility_timeout_seconds = var.sqs_dlq_visibility_timeout_seconds # Default: 30

  # SQS encryption
  sqs_managed_sse_enabled = var.sqs_dlq_sse_enabled # Default: true
  kms_master_key_id = var.sqs_dlq_kms_key_id # Default: null

  tags = local.common_tags
}

# SQS Queue for Lambda processing (if DLQ is enabled)
resource "aws_sqs_queue" "lambda_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = "${local.name_prefix}-lambda-queue"

  # Enhanced SQS configuration
  delay_seconds = var.sqs_lambda_delay_seconds # Default: 0
  max_message_size = var.sqs_lambda_max_message_size # Default: 262144 (256 KB)
  message_retention_seconds = var.sqs_lambda_message_retention_seconds # Default: 345600 (4 days)
  receive_wait_time_seconds = var.sqs_lambda_receive_wait_time_seconds # Default: 0
  visibility_timeout_seconds = var.sqs_lambda_visibility_timeout_seconds # Default: 30

  # SQS encryption
  sqs_managed_sse_enabled = var.sqs_lambda_sse_enabled # Default: true
  kms_master_key_id = var.sqs_lambda_kms_key_id # Default: null

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue[0].arn
    maxReceiveCount     = var.max_receive_count # Default: 3
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
  description      = var.lambda_description # Default: "Lambda function for S3 processing"
  role            = aws_iam_role.lambda_role.arn
  handler         = var.lambda_handler # Default: "index.handler"
  runtime         = var.lambda_runtime # Default: "python3.11"
  timeout         = var.lambda_timeout # Default: 30 seconds
  memory_size     = var.lambda_memory_size # Default: 128 MB
  source_code_hash = var.lambda_source_path != null ? data.archive_file.lambda_zip[0].output_base64sha256 : var.lambda_source_code_hash

  # Enhanced Lambda configuration
  publish = var.lambda_publish # Default: false
  kms_key_arn = var.lambda_kms_key_arn # Default: null

  # Lambda architectures
  architectures = var.lambda_architectures # Default: ["x86_64"]

  # Lambda ephemeral storage
  ephemeral_storage {
    size = var.lambda_ephemeral_storage.size # Default: 512 MB
  }

  # Lambda tracing configuration
  tracing_config {
    mode = var.lambda_tracing_config.mode # Default: "PassThrough"
  }

  # Lambda dead letter configuration
  dynamic "dead_letter_config" {
    for_each = var.lambda_dead_letter_config != null ? [var.lambda_dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # Lambda image configuration
  dynamic "image_config" {
    for_each = var.lambda_image_config != null ? [var.lambda_image_config] : []
    content {
      entry_point       = image_config.value.entry_point
      command          = image_config.value.command
      working_directory = image_config.value.working_directory
    }
  }

  # Lambda file system configuration
  dynamic "file_system_config" {
    for_each = var.lambda_file_system_config != null ? [var.lambda_file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  # Lambda snap start configuration
  dynamic "snap_start" {
    for_each = var.lambda_snap_start != null ? [var.lambda_snap_start] : []
    content {
      apply_on = snap_start.value.apply_on
    }
  }

  # Lambda code signing configuration
  code_signing_config_arn = var.lambda_code_signing_config_arn # Default: null

  # Lambda package type and image URI
  package_type = var.lambda_package_type # Default: "Zip"
  image_uri    = var.lambda_image_uri # Default: null

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

  layers = var.lambda_layers # Default: empty list

  reserved_concurrent_executions = var.lambda_reserved_concurrency # Default: null (unlimited)

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
  retention_in_days = var.cloudwatch_log_retention_days # Default: 7 days

  # Enhanced CloudWatch Log Group configuration
  kms_key_id = var.cloudwatch_log_kms_key_id # Default: null

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

  # Enhanced CloudWatch Alarm configuration
  treat_missing_data = each.value.treat_missing_data # Default: "missing"
  datapoints_to_alarm = each.value.datapoints_to_alarm # Default: null
  threshold_metric_id = each.value.threshold_metric_id # Default: null

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
      filter_prefix       = var.s3_filter_prefix # Default: null
      filter_suffix       = var.s3_filter_suffix # Default: null
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
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
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
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
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
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.lambda_queue[0].arn,
          aws_sqs_queue.dead_letter_queue[0].arn
        ]
      }
    ]
  })
}

# S3 Bucket Policy (if custom policy is provided)
resource "aws_s3_bucket_policy" "main" {
  count  = var.s3_bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.main.id
  policy = var.s3_bucket_policy
} 