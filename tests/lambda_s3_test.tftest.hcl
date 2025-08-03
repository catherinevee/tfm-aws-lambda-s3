variables {
  module_name         = "test"
  environment         = "dev"
  lambda_function_name = "test-lambda"
  s3_bucket_name      = "test-bucket-123"
}

run "validate_lambda_configuration" {
  command = plan

  assert {
    condition     = aws_lambda_function.main.runtime == "python3.11"
    error_message = "Lambda runtime should default to python3.11"
  }

  assert {
    condition     = aws_lambda_function.main.memory_size == 128
    error_message = "Lambda memory size should default to 128 MB"
  }

  assert {
    condition     = aws_lambda_function.main.timeout == 30
    error_message = "Lambda timeout should default to 30 seconds"
  }
}

run "validate_s3_configuration" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.force_destroy == false
    error_message = "S3 bucket force_destroy should default to false"
  }

  assert {
    condition     = aws_s3_bucket_versioning.main[0].versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled by default"
  }
}

run "validate_iam_configuration" {
  command = plan

  assert {
    condition     = can(aws_iam_role.lambda_role.name)
    error_message = "IAM role should be created"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.lambda_basic_execution) > 0
    error_message = "Lambda basic execution policy should be attached"
  }
}

run "validate_monitoring_configuration" {
  command = plan

  assert {
    condition     = can(aws_cloudwatch_log_group.lambda_logs.name)
    error_message = "CloudWatch log group should be created"
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda_logs.retention_in_days == 30
    error_message = "Log retention should default to 30 days"
  }
}

run "validate_invalid_environment" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [
    var.environment,
  ]
}
