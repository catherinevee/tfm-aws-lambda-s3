# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name                  = local.lambda_role_name
  description           = var.lambda_role_description
  path                  = var.lambda_role_path
  permissions_boundary  = var.lambda_role_permissions_boundary
  max_session_duration  = var.lambda_role_max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, var.lambda_role_tags)
}

# IAM Policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda VPC execution
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count      = var.lambda_vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_custom_policy" {
  count  = var.lambda_custom_policy != null ? 1 : 0
  name   = "${local.name_prefix}-lambda-custom-policy"
  role   = aws_iam_role.lambda_role.id
  policy = var.lambda_custom_policy
}

# Additional IAM Policy ARNs attachment
resource "aws_iam_role_policy_attachment" "lambda_additional_policies" {
  for_each   = toset(var.lambda_role_policy_arns)
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

# S3 Bucket Access Policy
resource "aws_iam_role_policy" "s3_access" {
  name = "${local.name_prefix}-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}
