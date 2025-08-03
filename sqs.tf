# Dead Letter Queue
resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = local.dlq_name

  message_retention_seconds = var.dlq_message_retention_seconds
  visibility_timeout_seconds = var.dlq_visibility_timeout_seconds
  max_message_size          = var.dlq_max_message_size
  delay_seconds             = var.dlq_delay_seconds

  kms_master_key_id                 = var.dlq_kms_key_id
  kms_data_key_reuse_period_seconds = var.dlq_kms_data_key_reuse_period_seconds

  tags = merge(local.common_tags, {
    Name = local.dlq_name
  })
}

# Lambda Processing Queue
resource "aws_sqs_queue" "lambda_queue" {
  count = var.enable_dead_letter_queue ? 1 : 0
  name  = "${local.name_prefix}-queue"

  visibility_timeout_seconds = var.lambda_queue_visibility_timeout_seconds
  message_retention_seconds  = var.lambda_queue_message_retention_seconds
  max_message_size          = var.lambda_queue_max_message_size
  delay_seconds             = var.lambda_queue_delay_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue[0].arn
    maxReceiveCount     = var.lambda_queue_max_receive_count
  })

  kms_master_key_id                 = var.lambda_queue_kms_key_id
  kms_data_key_reuse_period_seconds = var.lambda_queue_kms_data_key_reuse_period_seconds

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-queue"
  })
}
