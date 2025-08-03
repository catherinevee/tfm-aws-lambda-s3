# Simple Example of Lambda S3 Integration

provider "aws" {
  region = "us-west-2"
}

module "lambda_s3_simple" {
  source = "../../"

  module_name    = "simple"
  environment    = "dev"
  
  # Lambda Configuration
  lambda_function_name = "simple-lambda-function"
  lambda_description  = "Simple Lambda function for S3 processing"
  lambda_runtime      = "python3.11"
  lambda_handler     = "index.handler"
  
  # S3 Configuration
  s3_bucket_name          = "simple-lambda-bucket-123"
  s3_bucket_force_destroy = true

  tags = {
    Project = "Simple Example"
  }
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_s3_simple.lambda_function_name
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.lambda_s3_simple.s3_bucket_id
}
