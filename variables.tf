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

# ==============================================================================
# Enhanced Lambda Function Configuration Variables
# ==============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    name = string
    description = optional(string, null)
    runtime = optional(string, "python3.11")
    handler = optional(string, "index.handler")
    timeout = optional(number, 30)
    memory_size = optional(number, 128)
    
    # Source code configuration
    source_path = optional(string, null)
    source_code_hash = optional(string, null)
    s3_bucket = optional(string, null)
    s3_key = optional(string, null)
    s3_object_version = optional(string, null)
    image_uri = optional(string, null)
    
    # Image configuration
    image_config = optional(object({
      command = optional(list(string), [])
      entry_point = optional(list(string), [])
      working_directory = optional(string, null)
    }), {})
    
    # VPC configuration
    vpc_config = optional(object({
      subnet_ids = list(string)
      security_group_ids = list(string)
    }), {})
    
    # File system configuration
    file_system_config = optional(object({
      arn = string
      local_mount_path = string
    }), {})
    
    # Dead letter configuration
    dead_letter_config = optional(object({
      target_arn = string
    }), {})
    
    # Tracing configuration
    tracing_config = optional(object({
      mode = optional(string, "PassThrough")
    }), {})
    
    # KMS configuration
    kms_key_arn = optional(string, null)
    
    # Layers
    layers = optional(list(string), [])
    
    # Runtime management
    runtime_management_config = optional(object({
      update_runtime_on = optional(string, "Auto")
      runtime_version_arn = optional(string, null)
    }), {})
    
    # Snap start
    snap_start = optional(object({
      apply_on = string
    }), {})
    
    # Ephemeral storage
    ephemeral_storage = optional(object({
      size = optional(number, 512)
    }), {})
    
    # Function URL
    function_url = optional(object({
      authorization_type = optional(string, "NONE")
      cors = optional(object({
        allow_credentials = optional(bool, null)
        allow_origins = optional(list(string), [])
        allow_methods = optional(list(string), [])
        allow_headers = optional(list(string), [])
        expose_headers = optional(list(string), [])
        max_age = optional(number, null)
      }), {})
    }), {})
    
    # Event source mappings
    event_source_mappings = optional(list(object({
      event_source_arn = string
      function_name = optional(string, null)
      enabled = optional(bool, true)
      batch_size = optional(number, 100)
      maximum_batching_window_in_seconds = optional(number, 0)
      parallelization_factor = optional(number, 1)
      starting_position = optional(string, "LATEST")
      starting_position_timestamp = optional(string, null)
      destination_config = optional(object({
        on_failure = optional(object({
          destination_arn = string
        }), {})
        on_success = optional(object({
          destination_arn = string
        }), {})
      }), {})
      filter_criteria = optional(object({
        filters = optional(list(object({
          pattern = string
        })), [])
      }), {})
      function_response_types = optional(list(string), [])
      maximum_record_age_in_seconds = optional(number, null)
      maximum_retry_attempts = optional(number, null)
      scaling_config = optional(object({
        maximum_concurrency = optional(number, null)
      }), {})
      self_managed_event_source = optional(object({
        endpoints = map(string)
      }), {})
      source_access_configurations = optional(list(object({
        type = string
        uri = string
      })), [])
      tumbling_window_in_seconds = optional(number, null)
    })), [])
    
    # Aliases
    aliases = optional(list(object({
      name = string
      function_version = string
      description = optional(string, null)
      routing_config = optional(object({
        additional_version_weights = optional(map(number), {})
        additional_version_weights = optional(map(number), {})
      }), {})
    })), [])
    
    # Provisioned concurrency
    provisioned_concurrency_configs = optional(list(object({
      qualifier = string
      provisioned_concurrent_executions = number
    })), [])
    
    # Code signing
    code_signing_config = optional(object({
      description = optional(string, null)
      allowed_publishers = object({
        signing_profile_version_arns = optional(list(string), [])
      })
      policies = optional(object({
        untrusted_artifact_on_deployment = string
      }), {})
    }), {})
    
    # Reserved concurrency
    reserved_concurrent_executions = optional(number, null)
    
    # Publish
    publish = optional(bool, false)
    
    # Version description
    version_description = optional(string, null)
    
    # Environment variables
    environment_variables = optional(map(string), {})
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Configuration Variables
# ==============================================================================

variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    name = string
    force_destroy = optional(bool, false)
    
    # ACL configuration
    acl = optional(string, null)
    grant = optional(list(object({
      id = optional(string, null)
      type = string
      uri = optional(string, null)
      permissions = list(string)
    })), [])
    
    # Versioning
    versioning = optional(object({
      enabled = optional(bool, false)
      mfa_delete = optional(bool, false)
    }), {})
    
    # Server-side encryption
    server_side_encryption_configuration = optional(object({
      rule = object({
        apply_server_side_encryption_by_default = object({
          sse_algorithm = string
          kms_master_key_id = optional(string, null)
        })
        bucket_key_enabled = optional(bool, null)
      })
    }), {})
    
    # Object lifecycle
    lifecycle_rule = optional(list(object({
      id = optional(string, null)
      prefix = optional(string, null)
      tags = optional(map(string), {})
      enabled = optional(bool, true)
      
      abort_incomplete_multipart_upload = optional(object({
        days_after_initiation = number
      }), {})
      
      expiration = optional(object({
        date = optional(string, null)
        days = optional(number, null)
        expired_object_delete_marker = optional(bool, null)
      }), {})
      
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
        newer_noncurrent_versions = optional(number, null)
      }), {})
      
      noncurrent_version_transition = optional(list(object({
        noncurrent_days = number
        storage_class = string
        newer_noncurrent_versions = optional(number, null)
      })), [])
      
      transition = optional(list(object({
        date = optional(string, null)
        days = optional(number, null)
        storage_class = string
      })), [])
      
      object_size_greater_than = optional(number, null)
      object_size_less_than = optional(number, null)
    })), [])
    
    # CORS configuration
    cors_rule = optional(list(object({
      allowed_headers = optional(list(string), [])
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers = optional(list(string), [])
      max_age_seconds = optional(number, null)
    })), [])
    
    # Website configuration
    website = optional(object({
      index_document = optional(string, null)
      error_document = optional(string, null)
      redirect_all_requests_to = optional(string, null)
      routing_rules = optional(string, null)
    }), {})
    
    # Object ownership
    object_ownership = optional(object({
      object_ownership = string
      rule = optional(object({
        object_ownership = string
      }), {})
    }), {})
    
    # Public access block
    block_public_acls = optional(bool, true)
    block_public_policy = optional(bool, true)
    ignore_public_acls = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
    
    # Bucket ownership controls
    bucket_ownership_controls = optional(object({
      rule = object({
        object_ownership = string
      })
    }), {})
    
    # Intelligent tiering
    intelligent_tiering = optional(list(object({
      id = string
      status = optional(string, "Enabled")
      tiering = list(object({
        access_tier = string
        days = number
      }))
    })), [])
    
    # Metrics
    metric_configuration = optional(list(object({
      id = string
      filter = optional(object({
        prefix = optional(string, null)
        tags = optional(map(string), {})
      }), {})
    })), [])
    
    # Inventory
    inventory = optional(list(object({
      name = string
      enabled = optional(bool, true)
      included_object_versions = optional(string, "Current")
      schedule = object({
        frequency = string
      })
      destination = object({
        bucket = object({
          format = string
          bucket_arn = string
          account_id = optional(string, null)
          prefix = optional(string, null)
          encryption = optional(object({
            sse_kms = optional(object({
              key_id = string
            }), {})
            sse_s3 = optional(object({}), {})
          }), {})
        })
      })
      optional_fields = optional(list(string), [])
    })), [])
    
    # Object lock
    object_lock_configuration = optional(object({
      object_lock_enabled = optional(string, "Enabled")
      rule = optional(object({
        default_retention = object({
          mode = string
          days = optional(number, null)
          years = optional(number, null)
        })
      }), {})
    }), {})
    
    # Replication
    replication_configuration = optional(object({
      role = string
      rules = list(object({
        id = optional(string, null)
        status = optional(string, "Enabled")
        priority = optional(number, null)
        delete_marker_replication = optional(object({
          status = string
        }), {})
        destination = object({
          bucket = string
          storage_class = optional(string, null)
          replica_kms_key_id = optional(string, null)
          account_id = optional(string, null)
          access_control_translation = optional(object({
            owner = string
          }), {})
          replication_time = optional(object({
            status = string
            minutes = optional(number, null)
          }), {})
          metrics = optional(object({
            status = string
            minutes = optional(number, null)
          }), {})
        })
        source_selection_criteria = optional(object({
          sse_kms_encrypted_objects = optional(object({
            status = string
          }), {})
        }), {})
        filter = optional(object({
          prefix = optional(string, null)
          tags = optional(map(string), {})
        }), {})
      }))
    }), {})
    
    # Request payer
    request_payer = optional(string, null)
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Event Notifications
# ==============================================================================

variable "s3_event_notifications" {
  description = "Map of S3 event notifications to create"
  type = map(object({
    bucket = string
    eventbridge = optional(bool, false)
    lambda = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      lambda_function_arn = string
    })), [])
    queue = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      queue_arn = string
    })), [])
    topic = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      topic_arn = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Policy
# ==============================================================================

variable "s3_bucket_policies" {
  description = "Map of S3 bucket policies to create"
  type = map(object({
    bucket = string
    policy = string
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Public Access Block
# ==============================================================================

variable "s3_bucket_public_access_blocks" {
  description = "Map of S3 bucket public access blocks to create"
  type = map(object({
    bucket = string
    block_public_acls = optional(bool, true)
    block_public_policy = optional(bool, true)
    ignore_public_acls = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Versioning
# ==============================================================================

variable "s3_bucket_versionings" {
  description = "Map of S3 bucket versionings to create"
  type = map(object({
    bucket = string
    enabled = optional(bool, false)
    mfa_delete = optional(bool, false)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Server Side Encryption Configuration
# ==============================================================================

variable "s3_bucket_server_side_encryption_configurations" {
  description = "Map of S3 bucket server side encryption configurations to create"
  type = map(object({
    bucket = string
    rule = object({
      apply_server_side_encryption_by_default = object({
        sse_algorithm = string
        kms_master_key_id = optional(string, null)
      })
      bucket_key_enabled = optional(bool, null)
    })
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Lifecycle Configuration
# ==============================================================================

variable "s3_bucket_lifecycle_configurations" {
  description = "Map of S3 bucket lifecycle configurations to create"
  type = map(object({
    bucket = string
    rule = list(object({
      id = optional(string, null)
      prefix = optional(string, null)
      tags = optional(map(string), {})
      enabled = optional(bool, true)
      
      abort_incomplete_multipart_upload = optional(object({
        days_after_initiation = number
      }), {})
      
      expiration = optional(object({
        date = optional(string, null)
        days = optional(number, null)
        expired_object_delete_marker = optional(bool, null)
      }), {})
      
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
        newer_noncurrent_versions = optional(number, null)
      }), {})
      
      noncurrent_version_transition = optional(list(object({
        noncurrent_days = number
        storage_class = string
        newer_noncurrent_versions = optional(number, null)
      })), [])
      
      transition = optional(list(object({
        date = optional(string, null)
        days = optional(number, null)
        storage_class = string
      })), [])
      
      object_size_greater_than = optional(number, null)
      object_size_less_than = optional(number, null)
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket CORS Configuration
# ==============================================================================

variable "s3_bucket_cors_configurations" {
  description = "Map of S3 bucket CORS configurations to create"
  type = map(object({
    bucket = string
    cors_rule = list(object({
      allowed_headers = optional(list(string), [])
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers = optional(list(string), [])
      max_age_seconds = optional(number, null)
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Website Configuration
# ==============================================================================

variable "s3_bucket_website_configurations" {
  description = "Map of S3 bucket website configurations to create"
  type = map(object({
    bucket = string
    index_document = optional(string, null)
    error_document = optional(string, null)
    redirect_all_requests_to = optional(string, null)
    routing_rules = optional(string, null)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object Ownership Controls
# ==============================================================================

variable "s3_bucket_ownership_controls" {
  description = "Map of S3 bucket ownership controls to create"
  type = map(object({
    bucket = string
    rule = object({
      object_ownership = string
    })
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Intelligent Tiering
# ==============================================================================

variable "s3_bucket_intelligent_tiering_configurations" {
  description = "Map of S3 bucket intelligent tiering configurations to create"
  type = map(object({
    bucket = string
    name = string
    status = optional(string, "Enabled")
    tiering = list(object({
      access_tier = string
      days = number
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Metrics
# ==============================================================================

variable "s3_bucket_metric_configurations" {
  description = "Map of S3 bucket metric configurations to create"
  type = map(object({
    bucket = string
    name = string
    filter = optional(object({
      prefix = optional(string, null)
      tags = optional(map(string), {})
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Inventory
# ==============================================================================

variable "s3_bucket_inventory_configurations" {
  description = "Map of S3 bucket inventory configurations to create"
  type = map(object({
    bucket = string
    name = string
    enabled = optional(bool, true)
    included_object_versions = optional(string, "Current")
    schedule = object({
      frequency = string
    })
    destination = object({
      bucket = object({
        format = string
        bucket_arn = string
        account_id = optional(string, null)
        prefix = optional(string, null)
        encryption = optional(object({
          sse_kms = optional(object({
            key_id = string
          }), {})
          sse_s3 = optional(object({}), {})
        }), {})
      })
    })
    optional_fields = optional(list(string), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object Lock Configuration
# ==============================================================================

variable "s3_bucket_object_lock_configurations" {
  description = "Map of S3 bucket object lock configurations to create"
  type = map(object({
    bucket = string
    object_lock_enabled = optional(string, "Enabled")
    rule = optional(object({
      default_retention = object({
        mode = string
        days = optional(number, null)
        years = optional(number, null)
      })
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Replication Configuration
# ==============================================================================

variable "s3_bucket_replication_configurations" {
  description = "Map of S3 bucket replication configurations to create"
  type = map(object({
    bucket = string
    role = string
    rules = list(object({
      id = optional(string, null)
      status = optional(string, "Enabled")
      priority = optional(number, null)
      delete_marker_replication = optional(object({
        status = string
      }), {})
      destination = object({
        bucket = string
        storage_class = optional(string, null)
        replica_kms_key_id = optional(string, null)
        account_id = optional(string, null)
        access_control_translation = optional(object({
          owner = string
        }), {})
        replication_time = optional(object({
          status = string
          minutes = optional(number, null)
        }), {})
        metrics = optional(object({
          status = string
          minutes = optional(number, null)
        }), {})
      })
      source_selection_criteria = optional(object({
        sse_kms_encrypted_objects = optional(object({
          status = string
        }), {})
      }), {})
      filter = optional(object({
        prefix = optional(string, null)
        tags = optional(map(string), {})
      }), {})
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Request Payer
# ==============================================================================

variable "s3_bucket_request_payers" {
  description = "Map of S3 bucket request payers to create"
  type = map(object({
    bucket = string
    request_payer = string
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Accelerate Configuration
# ==============================================================================

variable "s3_bucket_accelerate_configurations" {
  description = "Map of S3 bucket accelerate configurations to create"
  type = map(object({
    bucket = string
    status = string
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Analytics Configuration
# ==============================================================================

variable "s3_bucket_analytics_configurations" {
  description = "Map of S3 bucket analytics configurations to create"
  type = map(object({
    bucket = string
    name = string
    filter = optional(object({
      prefix = optional(string, null)
      tags = optional(map(string), {})
    }), {})
    storage_class_analysis = optional(object({
      data_export = optional(object({
        destination = object({
          bucket_arn = string
          bucket_account_id = optional(string, null)
          format = string
          prefix = optional(string, null)
        })
        output_schema_version = string
      }), {})
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Logging
# ==============================================================================

variable "s3_bucket_loggings" {
  description = "Map of S3 bucket loggings to create"
  type = map(object({
    bucket = string
    target_bucket = string
    target_prefix = optional(string, null)
    target_grant = optional(list(object({
      grantee = object({
        id = optional(string, null)
        type = string
        uri = optional(string, null)
        email_address = optional(string, null)
        display_name = optional(string, null)
      })
      permission = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Notification
# ==============================================================================

variable "s3_bucket_notifications" {
  description = "Map of S3 bucket notifications to create"
  type = map(object({
    bucket = string
    eventbridge = optional(bool, false)
    lambda = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      lambda_function_arn = string
    })), [])
    queue = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      queue_arn = string
    })), [])
    topic = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      topic_arn = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object
# ==============================================================================

variable "s3_bucket_objects" {
  description = "Map of S3 bucket objects to create"
  type = map(object({
    bucket = string
    key = string
    source = optional(string, null)
    content = optional(string, null)
    content_base64 = optional(string, null)
    content_type = optional(string, null)
    content_disposition = optional(string, null)
    content_encoding = optional(string, null)
    content_language = optional(string, null)
    website_redirect = optional(string, null)
    etag = optional(string, null)
    force_destroy = optional(bool, false)
    metadata = optional(map(string), {})
    object_lock_legal_hold_status = optional(string, null)
    object_lock_mode = optional(string, null)
    object_lock_retain_until_date = optional(string, null)
    server_side_encryption = optional(string, null)
    source_hash = optional(string, null)
    storage_class = optional(string, null)
    tags = optional(map(string), {})
    kms_key_id = optional(string, null)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Public Access Block
# ==============================================================================

variable "s3_bucket_public_access_blocks" {
  description = "Map of S3 bucket public access blocks to create"
  type = map(object({
    bucket = string
    block_public_acls = optional(bool, true)
    block_public_policy = optional(bool, true)
    ignore_public_acls = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Versioning
# ==============================================================================

variable "s3_bucket_versionings" {
  description = "Map of S3 bucket versionings to create"
  type = map(object({
    bucket = string
    enabled = optional(bool, false)
    mfa_delete = optional(bool, false)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Server Side Encryption Configuration
# ==============================================================================

variable "s3_bucket_server_side_encryption_configurations" {
  description = "Map of S3 bucket server side encryption configurations to create"
  type = map(object({
    bucket = string
    rule = object({
      apply_server_side_encryption_by_default = object({
        sse_algorithm = string
        kms_master_key_id = optional(string, null)
      })
      bucket_key_enabled = optional(bool, null)
    })
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Lifecycle Configuration
# ==============================================================================

variable "s3_bucket_lifecycle_configurations" {
  description = "Map of S3 bucket lifecycle configurations to create"
  type = map(object({
    bucket = string
    rule = list(object({
      id = optional(string, null)
      prefix = optional(string, null)
      tags = optional(map(string), {})
      enabled = optional(bool, true)
      
      abort_incomplete_multipart_upload = optional(object({
        days_after_initiation = number
      }), {})
      
      expiration = optional(object({
        date = optional(string, null)
        days = optional(number, null)
        expired_object_delete_marker = optional(bool, null)
      }), {})
      
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
        newer_noncurrent_versions = optional(number, null)
      }), {})
      
      noncurrent_version_transition = optional(list(object({
        noncurrent_days = number
        storage_class = string
        newer_noncurrent_versions = optional(number, null)
      })), [])
      
      transition = optional(list(object({
        date = optional(string, null)
        days = optional(number, null)
        storage_class = string
      })), [])
      
      object_size_greater_than = optional(number, null)
      object_size_less_than = optional(number, null)
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket CORS Configuration
# ==============================================================================

variable "s3_bucket_cors_configurations" {
  description = "Map of S3 bucket CORS configurations to create"
  type = map(object({
    bucket = string
    cors_rule = list(object({
      allowed_headers = optional(list(string), [])
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers = optional(list(string), [])
      max_age_seconds = optional(number, null)
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Website Configuration
# ==============================================================================

variable "s3_bucket_website_configurations" {
  description = "Map of S3 bucket website configurations to create"
  type = map(object({
    bucket = string
    index_document = optional(string, null)
    error_document = optional(string, null)
    redirect_all_requests_to = optional(string, null)
    routing_rules = optional(string, null)
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object Ownership Controls
# ==============================================================================

variable "s3_bucket_ownership_controls" {
  description = "Map of S3 bucket ownership controls to create"
  type = map(object({
    bucket = string
    rule = object({
      object_ownership = string
    })
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Intelligent Tiering
# ==============================================================================

variable "s3_bucket_intelligent_tiering_configurations" {
  description = "Map of S3 bucket intelligent tiering configurations to create"
  type = map(object({
    bucket = string
    name = string
    status = optional(string, "Enabled")
    tiering = list(object({
      access_tier = string
      days = number
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Metrics
# ==============================================================================

variable "s3_bucket_metric_configurations" {
  description = "Map of S3 bucket metric configurations to create"
  type = map(object({
    bucket = string
    name = string
    filter = optional(object({
      prefix = optional(string, null)
      tags = optional(map(string), {})
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Inventory
# ==============================================================================

variable "s3_bucket_inventory_configurations" {
  description = "Map of S3 bucket inventory configurations to create"
  type = map(object({
    bucket = string
    name = string
    enabled = optional(bool, true)
    included_object_versions = optional(string, "Current")
    schedule = object({
      frequency = string
    })
    destination = object({
      bucket = object({
        format = string
        bucket_arn = string
        account_id = optional(string, null)
        prefix = optional(string, null)
        encryption = optional(object({
          sse_kms = optional(object({
            key_id = string
          }), {})
          sse_s3 = optional(object({}), {})
        }), {})
      })
    })
    optional_fields = optional(list(string), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object Lock Configuration
# ==============================================================================

variable "s3_bucket_object_lock_configurations" {
  description = "Map of S3 bucket object lock configurations to create"
  type = map(object({
    bucket = string
    object_lock_enabled = optional(string, "Enabled")
    rule = optional(object({
      default_retention = object({
        mode = string
        days = optional(number, null)
        years = optional(number, null)
      })
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Replication Configuration
# ==============================================================================

variable "s3_bucket_replication_configurations" {
  description = "Map of S3 bucket replication configurations to create"
  type = map(object({
    bucket = string
    role = string
    rules = list(object({
      id = optional(string, null)
      status = optional(string, "Enabled")
      priority = optional(number, null)
      delete_marker_replication = optional(object({
        status = string
      }), {})
      destination = object({
        bucket = string
        storage_class = optional(string, null)
        replica_kms_key_id = optional(string, null)
        account_id = optional(string, null)
        access_control_translation = optional(object({
          owner = string
        }), {})
        replication_time = optional(object({
          status = string
          minutes = optional(number, null)
        }), {})
        metrics = optional(object({
          status = string
          minutes = optional(number, null)
        }), {})
      })
      source_selection_criteria = optional(object({
        sse_kms_encrypted_objects = optional(object({
          status = string
        }), {})
      }), {})
      filter = optional(object({
        prefix = optional(string, null)
        tags = optional(map(string), {})
      }), {})
    }))
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Request Payer
# ==============================================================================

variable "s3_bucket_request_payers" {
  description = "Map of S3 bucket request payers to create"
  type = map(object({
    bucket = string
    request_payer = string
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Accelerate Configuration
# ==============================================================================

variable "s3_bucket_accelerate_configurations" {
  description = "Map of S3 bucket accelerate configurations to create"
  type = map(object({
    bucket = string
    status = string
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Analytics Configuration
# ==============================================================================

variable "s3_bucket_analytics_configurations" {
  description = "Map of S3 bucket analytics configurations to create"
  type = map(object({
    bucket = string
    name = string
    filter = optional(object({
      prefix = optional(string, null)
      tags = optional(map(string), {})
    }), {})
    storage_class_analysis = optional(object({
      data_export = optional(object({
        destination = object({
          bucket_arn = string
          bucket_account_id = optional(string, null)
          format = string
          prefix = optional(string, null)
        })
        output_schema_version = string
      }), {})
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Logging
# ==============================================================================

variable "s3_bucket_loggings" {
  description = "Map of S3 bucket loggings to create"
  type = map(object({
    bucket = string
    target_bucket = string
    target_prefix = optional(string, null)
    target_grant = optional(list(object({
      grantee = object({
        id = optional(string, null)
        type = string
        uri = optional(string, null)
        email_address = optional(string, null)
        display_name = optional(string, null)
      })
      permission = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Notification
# ==============================================================================

variable "s3_bucket_notifications" {
  description = "Map of S3 bucket notifications to create"
  type = map(object({
    bucket = string
    eventbridge = optional(bool, false)
    lambda = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      lambda_function_arn = string
    })), [])
    queue = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      queue_arn = string
    })), [])
    topic = optional(list(object({
      events = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
      id = optional(string, null)
      topic_arn = string
    })), [])
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Bucket Object
# ==============================================================================

variable "s3_bucket_objects" {
  description = "Map of S3 bucket objects to create"
  type = map(object({
    bucket = string
    key = string
    source = optional(string, null)
    content = optional(string, null)
    content_base64 = optional(string, null)
    content_type = optional(string, null)
    content_disposition = optional(string, null)
    content_encoding = optional(string, null)
    content_language = optional(string, null)
    website_redirect = optional(string, null)
    etag = optional(string, null)
    force_destroy = optional(bool, false)
    metadata = optional(map(string), {})
    object_lock_legal_hold_status = optional(string, null)
    object_lock_mode = optional(string, null)
    object_lock_retain_until_date = optional(string, null)
    server_side_encryption = optional(string, null)
    source_hash = optional(string, null)
    storage_class = optional(string, null)
    tags = optional(map(string), {})
    kms_key_id = optional(string, null)
  }))
  default = {}
} 