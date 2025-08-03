# Lambda Function
resource "aws_lambda_function" "main" {
  filename         = var.lambda_source_path != null ? var.lambda_source_path : data.archive_file.lambda_zip[0].output_path
  source_code_hash = var.lambda_source_code_hash != null ? var.lambda_source_code_hash : data.archive_file.lambda_zip[0].output_base64sha256
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = var.lambda_handler
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  description     = var.lambda_description

  dynamic "vpc_config" {
    for_each = var.lambda_vpc_config != null ? [var.lambda_vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  environment {
    variables = var.lambda_environment_variables
  }

  dynamic "dead_letter_config" {
    for_each = var.enable_dead_letter_queue ? [aws_sqs_queue.dead_letter_queue[0].arn] : []
    content {
      target_arn = dead_letter_config.value
    }
  }

  layers = var.lambda_layers

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  tags = merge(local.common_tags, {
    Name = var.lambda_function_name
  })
}

# Lambda source code zip archive
data "archive_file" "lambda_zip" {
  count       = var.lambda_source_path == null ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content  = file("${path.module}/function/index.py")
    filename = "index.py"
  }
}

# Lambda permission for S3
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.main.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.main.arn
    events              = var.s3_events
    filter_prefix       = var.s3_filter_prefix
    filter_suffix       = var.s3_filter_suffix
  }

  depends_on = [aws_lambda_permission.s3]
}
