output "portfolio_id" {
  description = "Service Catalog Portfolio ID"
  value       = aws_servicecatalog_portfolio.secure_s3_portfolio.id
}

output "portfolio_arn" {
  description = "Service Catalog Portfolio ARN"
  value       = aws_servicecatalog_portfolio.secure_s3_portfolio.id
}

output "product_id" {
  description = "Service Catalog Product ID"
  value       = aws_servicecatalog_product.secure_s3_bucket.id
}

output "product_name" {
  description = "Service Catalog Product Name"
  value       = aws_servicecatalog_product.secure_s3_bucket.name
}

output "launch_role_arn" {
  description = "IAM role ARN used by Service Catalog to launch products"
  value       = aws_iam_role.service_catalog_launch_role.arn
}

output "end_user_role_arn" {
  description = "IAM role ARN that end users should assume to launch products"
  value       = aws_iam_role.service_catalog_end_user_role.arn
}

output "launch_instructions" {
  description = "Instructions for launching a secure S3 bucket"
  value = <<-EOT
    To launch a secure S3 bucket through Service Catalog:
    
    1. Navigate to AWS Service Catalog in the AWS Console
    2. Select the "${var.portfolio_name}" portfolio
    3. Click on "${var.product_name}" product
    4. Click "Launch" and fill in the parameters:
       - BucketNamePrefix: Choose a unique prefix for your bucket
       - EnableLogging: Set to "true" to enable access logging
       - LifecycleTransitionIADays: Days until transition to Standard-IA (default: ${var.lifecycle_ia_transition_days})
       - LifecycleTransitionGlacierDays: Days until transition to Glacier (default: ${var.lifecycle_glacier_transition_days})
       - LifecycleExpirationDays: Days until old versions expire (default: ${var.lifecycle_expiration_days})
       - Application, Environment, Owner: Add appropriate tags
    5. Provide a name for your provisioned product
    6. Click "Launch" to create the bucket
    
    The provisioned bucket will have:
    - SSE-S3 encryption enabled
    - Versioning enabled
    - Public access blocked
    - HTTPS-only access enforced
    - Lifecycle rules configured
    - Optional: Dedicated logging bucket if logging is enabled
    
    To destroy everything, run: terraform destroy
  EOT
}

output "cloudformation_template_s3_url" {
  description = "S3 URL of the CloudFormation template"
  value       = "https://${aws_s3_bucket.cloudformation_templates.bucket}.s3.${data.aws_region.current.id}.amazonaws.com/${aws_s3_object.cloudformation_template.key}"
}

