# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket        = var.s3_bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, var.s3_bucket_tags)
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  count  = var.s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.s3_bucket_versioning_status
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_bucket_encryption_algorithm
      kms_master_key_id = var.s3_bucket_kms_key_id
    }
    bucket_key_enabled = var.s3_bucket_key_enabled
  }
}

# S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}
