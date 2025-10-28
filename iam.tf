# IAM role for Service Catalog to launch products
resource "aws_iam_role" "service_catalog_launch_role" {
  name = "${var.product_name}-launch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "servicecatalog.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for Service Catalog launch role - permissions for creating S3 buckets
resource "aws_iam_role_policy" "service_catalog_launch_policy" {
  name = "${var.product_name}-launch-policy"
  role = aws_iam_role.service_catalog_launch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketEncryption",
          "s3:PutBucketLogging",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketPolicy",
          "s3:PutBucketLifecycleConfiguration",
          "s3:PutBucketTagging",
          "s3:PutBucketNotification",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetBucketLogging",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketPolicy",
          "s3:GetBucketLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:GetBucketNotificationConfiguration"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for end users to launch products from Service Catalog
resource "aws_iam_role" "service_catalog_end_user_role" {
  name = "${var.product_name}-end-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
      }
    ]
  })

  tags = var.tags
}

# Policy allowing end users to launch Service Catalog products
resource "aws_iam_role_policy" "service_catalog_end_user_policy" {
  name = "${var.product_name}-end-user-policy"
  role = aws_iam_role.service_catalog_end_user_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicecatalog:ListAcceptedPortfolioShares",
          "servicecatalog:ListPortfolios",
          "servicecatalog:GetProvisionedProductOutputs",
          "servicecatalog:ProvisionProduct",
          "servicecatalog:UpdateProvisionedProduct",
          "servicecatalog:ListProvisionedProducts",
          "servicecatalog:GetProvisionedProduct",
          "servicecatalog:TerminateProvisionedProduct"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackResources"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

