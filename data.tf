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
