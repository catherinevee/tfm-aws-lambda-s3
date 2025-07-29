# Module Variables
variable "module_name" {
  description = "Name of the module"
  type        = string
  default     = "lambda-s3-cloudwatch"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

# Lambda Function Variables
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.11"
  validation {
    condition     = contains(["python3.8", "python3.9", "python3.10", "python3.11", "python3.12", "nodejs18.x", "nodejs20.x", "java11", "java17", "go1.x", "dotnet6", "dotnet8"], var.lambda_runtime)
    error_message = "Runtime must be a supported AWS Lambda runtime."
  }
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "lambda_source_path" {
  description = "Path to the Lambda function source code"
  type        = string
  default     = null
}

variable "lambda_source_code_hash" {
  description = "Base64-encoded SHA256 hash of the Lambda function source code"
  type        = string
  default     = null
}

variable "lambda_environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency limit for the Lambda function"
  type        = number
  default     = null
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

# S3 Bucket Variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_bucket_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_public_access_block" {
  description = "Public access block configuration for the S3 bucket"
  type = object({
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
  })
  default = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

variable "s3_bucket_lifecycle_rules" {
  description = "Lifecycle rules for the S3 bucket"
  type = list(object({
    id      = string
    enabled = bool
    expiration = optional(object({
      days = number
    }))
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []
}

# CloudWatch Variables
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "Log retention days must be one of the supported values."
  }
}

variable "cloudwatch_alarms" {
  description = "CloudWatch alarms configuration"
  type = list(object({
    name          = string
    description   = string
    metric_name   = string
    namespace     = string
    statistic     = string
    period        = number
    evaluation_periods = number
    threshold     = number
    comparison_operator = string
    alarm_actions = list(string)
    ok_actions    = list(string)
    insufficient_data_actions = list(string)
  }))
  default = []
}

# IAM Variables
variable "lambda_role_name" {
  description = "Name of the IAM role for the Lambda function"
  type        = string
  default     = null
}

variable "lambda_role_policy_arns" {
  description = "List of IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "lambda_custom_policy" {
  description = "Custom IAM policy JSON for the Lambda function"
  type        = string
  default     = null
}

# EventBridge/CloudWatch Events Variables
variable "enable_s3_event_notification" {
  description = "Enable S3 event notifications to trigger Lambda"
  type        = bool
  default     = false
}

variable "s3_event_types" {
  description = "List of S3 event types to trigger Lambda"
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
  validation {
    condition = alltrue([
      for event in var.s3_event_types : contains([
        "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", 
        "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload",
        "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated"
      ], event)
    ])
    error_message = "S3 event types must be valid S3 event names."
  }
}

variable "s3_filter_prefix" {
  description = "S3 object key prefix filter for event notifications"
  type        = string
  default     = ""
}

variable "s3_filter_suffix" {
  description = "S3 object key suffix filter for event notifications"
  type        = string
  default     = ""
}

# VPC Configuration (Optional)
variable "lambda_vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Dead Letter Queue Configuration
variable "enable_dead_letter_queue" {
  description = "Enable SQS dead letter queue for failed Lambda executions"
  type        = bool
  default     = false
}

variable "dead_letter_queue_name" {
  description = "Name of the SQS dead letter queue"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to the dead letter queue"
  type        = number
  default     = 3
  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "Max receive count must be between 1 and 1000."
  }
} 