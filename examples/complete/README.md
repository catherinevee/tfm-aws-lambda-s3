# Complete Example

This example demonstrates a complete setup of the Lambda-S3 module with the following features:

* Lambda function triggered by S3 events
* S3 bucket with versioning and encryption
* Dead Letter Queue for failed executions
* CloudWatch monitoring and alarms
* Custom IAM roles and policies

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.13.0 |
| aws | ~> 6.2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 6.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| lambda_s3 | ../../ | n/a |

## Resources

No resources are created directly in this example. All resources are created by the module.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | ARN of the Lambda function |
| s3_bucket_id | ID of the S3 bucket |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
