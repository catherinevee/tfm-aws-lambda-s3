# Base Module Variables
variable "module_name" {
  description = "Name of the module"
  type        = string
  default     = "lambda-s3"
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
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.lambda_function_name))
    error_message = "Lambda function name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "lambda_description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function for S3 processing"
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
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240 && var.lambda_memory_size % 64 == 0
    error_message = "Memory size must be between 128 and 10240 MB and a multiple of 64 MB."
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
  validation {
    condition     = var.lambda_reserved_concurrency == null || var.lambda_reserved_concurrency >= 0
    error_message = "Reserved concurrency must be null or greater than or equal to 0."
  }
}

variable "lambda_layers" {
  description = "List of Lambda layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "lambda_publish" {
  description = "Whether to publish creation/change as new Lambda function version"
  type        = bool
  default     = false # Default: false
}

variable "lambda_kms_key_arn" {
  description = "KMS key ARN for Lambda function encryption"
  type        = string
  default     = null # Default: null
}

variable "lambda_image_config" {
  description = "Configuration for Lambda function image"
  type = object({
    entry_point       = list(string)
    command          = list(string)
    working_directory = string
  })
  default = null # Default: null
}

variable "lambda_file_system_config" {
  description = "Configuration for Lambda function file system"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null # Default: null
}

variable "lambda_tracing_config" {
  description = "Configuration for Lambda function tracing"
  type = object({
    mode = string
  })
  default = {
    mode = "PassThrough" # Default: "PassThrough"
  }
}

variable "lambda_dead_letter_config" {
  description = "Configuration for Lambda function dead letter queue"
  type = object({
    target_arn = string
  })
  default = null # Default: null
}

variable "lambda_architectures" {
  description = "List of Lambda function architectures"
  type        = list(string)
  default     = ["x86_64"] # Default: ["x86_64"]
  validation {
    condition = alltrue([
      for arch in var.lambda_architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architecture must be one of: x86_64, arm64."
  }
}

variable "lambda_ephemeral_storage" {
  description = "Configuration for Lambda function ephemeral storage"
  type = object({
    size = number
  })
  default = {
    size = 512 # Default: 512 MB
  }
  validation {
    condition = var.lambda_ephemeral_storage.size >= 512 && var.lambda_ephemeral_storage.size <= 10240
    error_message = "Ephemeral storage size must be between 512 and 10240 MB."
  }
}

variable "lambda_snap_start" {
  description = "Configuration for Lambda function snap start"
  type = object({
    apply_on = string
  })
  default = null # Default: null
  validation {
    condition = var.lambda_snap_start == null || contains(["PublishedVersions", "None"], var.lambda_snap_start.apply_on)
    error_message = "Snap start apply_on must be one of: PublishedVersions, None."
  }
}

variable "lambda_code_signing_config_arn" {
  description = "Code signing configuration ARN for Lambda function"
  type        = string
  default     = null # Default: null
}

variable "lambda_package_type" {
  description = "Package type for Lambda function"
  type        = string
  default     = "Zip" # Default: "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.lambda_package_type)
    error_message = "Package type must be one of: Zip, Image."
  }
}

variable "lambda_image_uri" {
  description = "ECR image URI for Lambda function (required if package_type is Image)"
  type        = string
  default     = null # Default: null
}

# Enhanced IAM Configuration
variable "lambda_role_name" {
  description = "Name of the IAM role for Lambda function"
  type        = string
  default     = null # Default: null (auto-generated)
}

variable "lambda_role_description" {
  description = "Description of the IAM role for Lambda function"
  type        = string
  default     = "IAM role for Lambda function" # Default: "IAM role for Lambda function"
}

variable "lambda_role_path" {
  description = "Path of the IAM role for Lambda function"
  type        = string
  default     = "/" # Default: "/"
}

variable "lambda_role_permissions_boundary" {
  description = "Permissions boundary ARN for the IAM role"
  type        = string
  default     = null # Default: null
}

variable "lambda_role_max_session_duration" {
  description = "Maximum session duration in seconds for the IAM role"
  type        = number
  default     = 3600 # Default: 3600 seconds (1 hour)
  validation {
    condition     = var.lambda_role_max_session_duration >= 3600 && var.lambda_role_max_session_duration <= 43200
    error_message = "Maximum session duration must be between 3600 and 43200 seconds."
  }
}

variable "lambda_role_policy_arns" {
  description = "List of IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = [] # Default: empty list
}

variable "lambda_custom_policy" {
  description = "Custom IAM policy document for Lambda function"
  type        = string
  default     = null # Default: null
}

variable "lambda_role_tags" {
  description = "Additional tags for the IAM role"
  type        = map(string)
  default     = {} # Default: empty map
}

# Enhanced VPC Configuration
variable "lambda_vpc_config" {
  description = "VPC configuration for Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null # Default: null
}

variable "lambda_vpc_config_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
  default     = [] # Default: empty list
}

variable "lambda_vpc_config_security_group_ids" {
  description = "List of security group IDs for Lambda VPC configuration"
  type        = list(string)
  default     = [] # Default: empty list
}

# Enhanced S3 Bucket Variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_bucket_force_destroy" {
  description = "Whether to force destroy the S3 bucket even if it contains objects"
  type        = bool
  default     = false # Default: false
}

variable "s3_bucket_description" {
  description = "Description for the S3 bucket"
  type        = string
  default     = "S3 bucket for Lambda processing" # Default: "S3 bucket for Lambda processing"
}

variable "s3_bucket_tags" {
  description = "Additional tags for the S3 bucket"
  type        = map(string)
  default     = {} # Default: empty map
}

variable "s3_bucket_versioning" {
  description = "Whether to enable versioning on the S3 bucket"
  type        = bool
  default     = false # Default: false
}

variable "s3_bucket_versioning_status" {
  description = "Versioning status for the S3 bucket"
  type        = string
  default     = "Enabled" # Default: "Enabled"
  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.s3_bucket_versioning_status)
    error_message = "Versioning status must be one of: Enabled, Suspended, Disabled."
  }
}

variable "s3_bucket_encryption" {
  description = "Whether to enable server-side encryption on the S3 bucket"
  type        = bool
  default     = true # Default: true
}

variable "s3_bucket_encryption_algorithm" {
  description = "Server-side encryption algorithm for the S3 bucket"
  type        = string
  default     = "AES256" # Default: "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.s3_bucket_encryption_algorithm)
    error_message = "Encryption algorithm must be one of: AES256, aws:kms."
  }
}

variable "s3_bucket_kms_key_id" {
  description = "KMS key ID for S3 bucket encryption (required if encryption_algorithm is aws:kms)"
  type        = string
  default     = null # Default: null
}

variable "s3_bucket_key_enabled" {
  description = "Whether to enable bucket key for S3 bucket"
  type        = bool
  default     = true # Default: true
}

variable "s3_bucket_public_access_block" {
  description = "Public access block configuration for S3 bucket"
  type = object({
    block_public_acls       = optional(bool, true) # Default: true
    block_public_policy     = optional(bool, true) # Default: true
    ignore_public_acls      = optional(bool, true) # Default: true
    restrict_public_buckets = optional(bool, true) # Default: true
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
    }), null) # Default: null
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }), null) # Default: null
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }), null) # Default: null
    transition = optional(list(object({
      days          = number
      storage_class = string
    })), []) # Default: empty list
    noncurrent_version_transition = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), []) # Default: empty list
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_cors_configuration" {
  description = "CORS configuration for the S3 bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_website_configuration" {
  description = "Website configuration for the S3 bucket"
  type = object({
    index_document = string
    error_document = optional(string, null) # Default: null
    redirect_all_requests_to = optional(string, null) # Default: null
    routing_rules = optional(string, null) # Default: null
  })
  default = null # Default: null
}

variable "s3_bucket_object_lock_configuration" {
  description = "Object lock configuration for the S3 bucket"
  type = object({
    object_lock_enabled = string
    rule = optional(object({
      default_retention = object({
        mode  = string
        days  = optional(number, null) # Default: null
        years = optional(number, null) # Default: null
      })
    }), null) # Default: null
  })
  default = null # Default: null
}

variable "s3_bucket_replication_configuration" {
  description = "Replication configuration for the S3 bucket"
  type = object({
    role = string
    rules = list(object({
      id       = string
      status   = string
      priority = optional(number, null) # Default: null
      destination = object({
        bucket             = string
        storage_class      = optional(string, null) # Default: null
        replica_kms_key_id = optional(string, null) # Default: null
        account            = optional(string, null) # Default: null
        access_control_translation = optional(object({
          owner = string
        }), null) # Default: null
        metrics = optional(object({
          status = string
          event_threshold = optional(object({
            minutes = number
          }), null) # Default: null
        }), null) # Default: null
      })
      source_selection_criteria = optional(object({
        sse_kms_encrypted_objects = optional(object({
          status = string
        }), null) # Default: null
      }), null) # Default: null
      filter = optional(object({
        prefix = optional(string, null) # Default: null
        tags   = optional(map(string), {}) # Default: empty map
      }), null) # Default: null
    }))
  })
  default = null # Default: null
}

variable "s3_bucket_intelligent_tiering_configuration" {
  description = "Intelligent tiering configuration for the S3 bucket"
  type = list(object({
    id     = string
    status = string
    tiering = list(object({
      access_tier = string
      days        = number
    }))
    filter = optional(object({
      prefix = optional(string, null) # Default: null
      tags   = optional(map(string), {}) # Default: empty map
    }), null) # Default: null
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_analytics_configuration" {
  description = "Analytics configuration for the S3 bucket"
  type = list(object({
    id = string
    filter = optional(object({
      prefix = optional(string, null) # Default: null
      tags   = optional(map(string), {}) # Default: empty map
    }), null) # Default: null
    storage_class_analysis = object({
      data_export = optional(object({
        destination = object({
          bucket_arn = string
          format     = string
          prefix     = optional(string, null) # Default: null
        })
      }), null) # Default: null
    })
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_inventory_configuration" {
  description = "Inventory configuration for the S3 bucket"
  type = list(object({
    id = string
    destination = object({
      bucket = object({
        format     = string
        bucket_arn = string
        account_id = optional(string, null) # Default: null
        prefix     = optional(string, null) # Default: null
        encryption = optional(object({
          sse_kms = optional(object({
            key_id = string
          }), null) # Default: null
          sse_s3 = optional(object({}), null) # Default: null
        }), null) # Default: null
      })
    })
    filter = optional(object({
      prefix = optional(string, null) # Default: null
    }), null) # Default: null
    included_object_versions = string
    optional_fields = optional(list(string), []) # Default: empty list
    schedule = object({
      frequency = string
    })
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_metric_configuration" {
  description = "Metric configuration for the S3 bucket"
  type = list(object({
    id = string
    filter = optional(object({
      prefix = optional(string, null) # Default: null
      tags   = optional(map(string), {}) # Default: empty map
    }), null) # Default: null
  }))
  default = [] # Default: empty list
}

variable "s3_bucket_notification_configuration" {
  description = "Notification configuration for the S3 bucket"
  type = object({
    lambda_configurations = optional(list(object({
      events              = list(string)
      filter_prefix       = optional(string, null) # Default: null
      filter_suffix       = optional(string, null) # Default: null
      lambda_function_arn = string
    })), []) # Default: empty list
    queue_configurations = optional(list(object({
      events        = list(string)
      filter_prefix = optional(string, null) # Default: null
      filter_suffix = optional(string, null) # Default: null
      queue_arn     = string
    })), []) # Default: empty list
    topic_configurations = optional(list(object({
      events        = list(string)
      filter_prefix = optional(string, null) # Default: null
      filter_suffix = optional(string, null) # Default: null
      topic_arn     = string
    })), []) # Default: empty list
  })
  default = null # Default: null
}

variable "s3_bucket_policy" {
  description = "Custom S3 bucket policy (if null, default policy is used)"
  type        = string
  default     = null # Default: null
}

variable "s3_bucket_ownership_controls" {
  description = "Ownership controls for the S3 bucket"
  type = object({
    rule = object({
      object_ownership = string
    })
  })
  default = null # Default: null
}

variable "s3_bucket_request_payer" {
  description = "Request payer configuration for the S3 bucket"
  type        = string
  default     = null # Default: null
  validation {
    condition = var.s3_bucket_request_payer == null || contains(["Requester", "BucketOwner"], var.s3_bucket_request_payer)
    error_message = "Request payer must be one of: Requester, BucketOwner."
  }
}

variable "s3_bucket_accelerate_configuration" {
  description = "Accelerate configuration for the S3 bucket"
  type = object({
    status = string
  })
  default = null # Default: null
  validation {
    condition = var.s3_bucket_accelerate_configuration == null || contains(["Enabled", "Suspended"], var.s3_bucket_accelerate_configuration.status)
    error_message = "Accelerate status must be one of: Enabled, Suspended."
  }
}

# Enhanced SQS Configuration Variables
variable "sqs_dlq_delay_seconds" {
  description = "Delay in seconds for the SQS dead letter queue"
  type        = number
  default     = 0 # Default: 0
  validation {
    condition     = var.sqs_dlq_delay_seconds >= 0 && var.sqs_dlq_delay_seconds <= 900
    error_message = "Delay seconds must be between 0 and 900."
  }
}

variable "sqs_dlq_max_message_size" {
  description = "Maximum message size in bytes for the SQS dead letter queue"
  type        = number
  default     = 262144 # Default: 262144 (256 KB)
  validation {
    condition     = var.sqs_dlq_max_message_size >= 1024 && var.sqs_dlq_max_message_size <= 262144
    error_message = "Maximum message size must be between 1024 and 262144 bytes."
  }
}

variable "sqs_dlq_message_retention_seconds" {
  description = "Message retention period in seconds for the SQS dead letter queue"
  type        = number
  default     = 345600 # Default: 345600 (4 days)
  validation {
    condition     = var.sqs_dlq_message_retention_seconds >= 60 && var.sqs_dlq_message_retention_seconds <= 1209600
    error_message = "Message retention seconds must be between 60 and 1209600."
  }
}

variable "sqs_dlq_receive_wait_time_seconds" {
  description = "Receive wait time in seconds for the SQS dead letter queue"
  type        = number
  default     = 0 # Default: 0
  validation {
    condition     = var.sqs_dlq_receive_wait_time_seconds >= 0 && var.sqs_dlq_receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "sqs_dlq_visibility_timeout_seconds" {
  description = "Visibility timeout in seconds for the SQS dead letter queue"
  type        = number
  default     = 30 # Default: 30
  validation {
    condition     = var.sqs_dlq_visibility_timeout_seconds >= 0 && var.sqs_dlq_visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds."
  }
}

variable "sqs_dlq_sse_enabled" {
  description = "Whether to enable server-side encryption for the SQS dead letter queue"
  type        = bool
  default     = true # Default: true
}

variable "sqs_dlq_kms_key_id" {
  description = "KMS key ID for SQS dead letter queue encryption"
  type        = string
  default     = null # Default: null
}

variable "sqs_lambda_delay_seconds" {
  description = "Delay in seconds for the SQS Lambda queue"
  type        = number
  default     = 0 # Default: 0
  validation {
    condition     = var.sqs_lambda_delay_seconds >= 0 && var.sqs_lambda_delay_seconds <= 900
    error_message = "Delay seconds must be between 0 and 900."
  }
}

variable "sqs_lambda_max_message_size" {
  description = "Maximum message size in bytes for the SQS Lambda queue"
  type        = number
  default     = 262144 # Default: 262144 (256 KB)
  validation {
    condition     = var.sqs_lambda_max_message_size >= 1024 && var.sqs_lambda_max_message_size <= 262144
    error_message = "Maximum message size must be between 1024 and 262144 bytes."
  }
}

variable "sqs_lambda_message_retention_seconds" {
  description = "Message retention period in seconds for the SQS Lambda queue"
  type        = number
  default     = 345600 # Default: 345600 (4 days)
  validation {
    condition     = var.sqs_lambda_message_retention_seconds >= 60 && var.sqs_lambda_message_retention_seconds <= 1209600
    error_message = "Message retention seconds must be between 60 and 1209600."
  }
}

variable "sqs_lambda_receive_wait_time_seconds" {
  description = "Receive wait time in seconds for the SQS Lambda queue"
  type        = number
  default     = 0 # Default: 0
  validation {
    condition     = var.sqs_lambda_receive_wait_time_seconds >= 0 && var.sqs_lambda_receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "sqs_lambda_visibility_timeout_seconds" {
  description = "Visibility timeout in seconds for the SQS Lambda queue"
  type        = number
  default     = 30 # Default: 30
  validation {
    condition     = var.sqs_lambda_visibility_timeout_seconds >= 0 && var.sqs_lambda_visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds."
  }
}

variable "sqs_lambda_sse_enabled" {
  description = "Whether to enable server-side encryption for the SQS Lambda queue"
  type        = bool
  default     = true # Default: true
}

variable "sqs_lambda_kms_key_id" {
  description = "KMS key ID for SQS Lambda queue encryption"
  type        = string
  default     = null # Default: null
}

# Enhanced CloudWatch Configuration Variables
variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null # Default: null
}

# Enhanced S3 Event Notification Variables
variable "enable_s3_event_notification" {
  description = "Whether to enable S3 event notifications to Lambda"
  type        = bool
  default     = false # Default: false
}

variable "s3_event_types" {
  description = "List of S3 event types to trigger Lambda function"
  type        = list(string)
  default     = ["s3:ObjectCreated:*"] # Default: ["s3:ObjectCreated:*"]
  validation {
    condition = alltrue([
      for event_type in var.s3_event_types : contains([
        "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload",
        "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated",
        "s3:ReducedRedundancyLostObject", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed"
      ], event_type)
    ])
    error_message = "Event type must be a valid S3 event type."
  }
}

variable "s3_filter_prefix" {
  description = "Prefix filter for S3 event notifications"
  type        = string
  default     = null # Default: null
}

variable "s3_filter_suffix" {
  description = "Suffix filter for S3 event notifications"
  type        = string
  default     = null # Default: null
}

# Enhanced Dead Letter Queue Variables
variable "enable_dead_letter_queue" {
  description = "Whether to enable SQS dead letter queue for Lambda"
  type        = bool
  default     = false # Default: false
}

variable "dead_letter_queue_name" {
  description = "Name of the SQS dead letter queue"
  type        = string
  default     = null # Default: null (auto-generated)
}

variable "max_receive_count" {
  description = "Maximum number of times a message is received before being sent to the dead letter queue"
  type        = number
  default     = 3 # Default: 3
  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "Max receive count must be between 1 and 1000."
  }
}

# Enhanced CloudWatch Alarms Variables
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7 # Default: 7 days
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "Log retention days must be one of the allowed values."
  }
}

variable "cloudwatch_alarms" {
  description = "List of CloudWatch alarms to create for Lambda monitoring"
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
    treat_missing_data = optional(string, "missing") # Default: "missing"
    datapoints_to_alarm = optional(number, null) # Default: null
    threshold_metric_id = optional(string, null) # Default: null
  }))
  default = [] # Default: empty list
} 