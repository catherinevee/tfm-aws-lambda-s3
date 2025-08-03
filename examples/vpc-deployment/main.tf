# VPC Deployment Example of Lambda S3 Integration

provider "aws" {
  region = "us-west-2"
}

module "lambda_s3_vpc" {
  source = "../../"

  module_name    = "vpc-example"
  environment    = "dev"
  
  # Lambda Configuration
  lambda_function_name = "vpc-lambda-function"
  lambda_description  = "Lambda function in VPC for S3 processing"
  lambda_runtime      = "python3.11"
  lambda_handler     = "index.handler"
  lambda_timeout     = 60
  lambda_memory_size = 512
  
  # VPC Configuration
  lambda_vpc_config = {
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    security_group_ids = ["sg-12345678"]
  }
  
  # S3 Configuration
  s3_bucket_name            = "vpc-lambda-bucket-123"
  s3_bucket_force_destroy   = true
  s3_bucket_versioning     = true
  
  tags = {
    Project     = "VPC Example"
    Environment = "Development"
  }
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_s3_vpc.lambda_function_arn
}

output "lambda_function_vpc_config" {
  description = "VPC configuration of the Lambda function"
  value       = module.lambda_s3_vpc.lambda_function_vpc_config
}
