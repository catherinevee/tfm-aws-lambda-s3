# Examples

This directory contains example configurations for the AWS Lambda + S3 + CloudWatch Terraform module.

## Available Examples

### Basic Example (`basic/`)

A simple implementation demonstrating:
- Basic Lambda function deployment
- S3 bucket creation with event notifications
- CloudWatch logging and alarms
- Minimal configuration for quick start

**Features:**
- Python Lambda function with S3 event processing
- S3 bucket with versioning and encryption
- CloudWatch alarms for errors and duration
- Event filtering by prefix and suffix

**Usage:**
```bash
cd examples/basic
terraform init
terraform plan
terraform apply
```

### Advanced Example (`advanced/`)

A comprehensive implementation demonstrating:
- VPC configuration for Lambda
- Dead letter queue for error handling
- Enhanced monitoring with SNS notifications
- S3 lifecycle management
- Custom IAM policies

**Features:**
- Lambda function in VPC with security groups
- SQS dead letter queue for failed executions
- SNS topic for CloudWatch alarm notifications
- S3 bucket lifecycle rules
- Enhanced error handling and logging
- Reserved concurrency configuration

**Usage:**
```bash
cd examples/advanced
terraform init
terraform plan
terraform apply
```

## Prerequisites

Before running the examples, ensure you have:

1. **Terraform** (>= 1.0) installed
2. **AWS CLI** configured with appropriate credentials
3. **AWS Provider** access to create resources
4. **Sufficient AWS permissions** for:
   - Lambda functions
   - S3 buckets
   - IAM roles and policies
   - CloudWatch logs and alarms
   - SQS queues (for advanced example)
   - SNS topics (for advanced example)
   - VPC resources (for advanced example)

## Configuration

Each example includes:
- `main.tf` - Main Terraform configuration
- `outputs.tf` - Output values for the deployed resources
- Lambda function source code (embedded in main.tf)

## Customization

You can customize the examples by:

1. **Modifying variables** in the module call
2. **Adding environment variables** to the Lambda function
3. **Configuring CloudWatch alarms** for specific metrics
4. **Adjusting S3 event filters** for your use case
5. **Adding custom IAM policies** for additional permissions

## Testing

To test the deployed Lambda functions:

1. **Upload a file** to the S3 bucket
2. **Check CloudWatch logs** for Lambda execution
3. **Monitor CloudWatch alarms** for any issues
4. **Verify S3 event notifications** are working

## Cleanup

To destroy the resources:

```bash
terraform destroy
```

**Note:** This will permanently delete all created resources including S3 buckets and their contents.

## Troubleshooting

### Common Issues

1. **S3 Bucket Name Conflicts**
   - S3 bucket names must be globally unique
   - Use the random suffix provided in examples

2. **IAM Permissions**
   - Ensure your AWS credentials have sufficient permissions
   - Check IAM role and policy configurations

3. **VPC Configuration (Advanced Example)**
   - Ensure subnets are in the correct availability zones
   - Verify security group rules allow necessary traffic

4. **Lambda Function Errors**
   - Check CloudWatch logs for detailed error messages
   - Verify Lambda function code syntax and dependencies

### Getting Help

1. Check the main module README.md for detailed documentation
2. Review the variables.tf file for all available options
3. Examine the outputs.tf file for available output values
4. Check CloudWatch logs for Lambda function execution details

## Security Considerations

- **S3 Bucket Security**: Public access is blocked by default
- **IAM Least Privilege**: Only necessary permissions are granted
- **Encryption**: S3 buckets use server-side encryption
- **VPC Isolation**: Advanced example includes VPC configuration
- **Dead Letter Queue**: Failed executions are captured for analysis

## Cost Optimization

- **Log Retention**: Adjust CloudWatch log retention periods
- **S3 Lifecycle**: Configure lifecycle rules to delete old versions
- **Lambda Concurrency**: Set appropriate reserved concurrency limits
- **Monitoring**: Use CloudWatch alarms to monitor costs and performance 