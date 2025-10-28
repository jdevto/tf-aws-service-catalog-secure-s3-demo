# Service Catalog Portfolio
resource "aws_servicecatalog_portfolio" "secure_s3_portfolio" {
  name          = var.portfolio_name
  description   = var.portfolio_description
  provider_name = "Terraform"

  tags = merge(
    var.tags,
    {
      Name = var.portfolio_name
    }
  )
}

# Service Catalog Product (define it before we can add versions)
resource "aws_servicecatalog_product" "secure_s3_bucket" {
  name              = var.product_name
  owner             = data.aws_caller_identity.current.account_id
  description       = var.product_description
  type              = "CLOUD_FORMATION_TEMPLATE"
  support_email     = "noreply@example.com"
  support_url       = ""
  support_description = "Contact administrator for support"

  # First provisioning artifact (version)
  provisioning_artifact_parameters {
    name        = var.product_version
    description = var.product_description
    template_url = "https://service-catalog-templates-${data.aws_caller_identity.current.account_id}.s3.${data.aws_region.current.id}.amazonaws.com/secure-s3-bucket-template.yaml"
    type        = "CLOUD_FORMATION_TEMPLATE"
  }

  tags = merge(
    var.tags,
    {
      Name = var.product_name
    }
  )

  depends_on = [
    aws_servicecatalog_portfolio.secure_s3_portfolio,
    aws_s3_object.cloudformation_template
  ]
}

# Upload CloudFormation template to S3 for Service Catalog to reference
resource "aws_s3_bucket" "cloudformation_templates" {
  bucket = "service-catalog-templates-${data.aws_caller_identity.current.account_id}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "cloudformation_templates" {
  bucket = aws_s3_bucket.cloudformation_templates.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudformation_templates" {
  bucket = aws_s3_bucket.cloudformation_templates.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudformation_templates" {
  bucket = aws_s3_bucket.cloudformation_templates.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets  = true
}

resource "aws_s3_object" "cloudformation_template" {
  bucket  = aws_s3_bucket.cloudformation_templates.bucket
  key     = "secure-s3-bucket-template.yaml"
  content = local.cloudformation_template
  etag    = md5(local.cloudformation_template)

  tags = var.tags
}

# Associate product with portfolio
resource "aws_servicecatalog_product_portfolio_association" "secure_s3_bucket" {
  portfolio_id   = aws_servicecatalog_portfolio.secure_s3_portfolio.id
  product_id     = aws_servicecatalog_product.secure_s3_bucket.id
}

# Note: Launch constraints are managed through the product's provisioning_artifact_parameters
# The launch role will be assigned when products are provisioned through Service Catalog

# Grant end user role access to the portfolio
resource "aws_servicecatalog_principal_portfolio_association" "end_user_access" {
  portfolio_id  = aws_servicecatalog_portfolio.secure_s3_portfolio.id
  principal_arn = aws_iam_role.service_catalog_end_user_role.arn
}

