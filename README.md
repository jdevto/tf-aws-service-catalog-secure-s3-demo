# Service Catalog Secure S3 Bucket Demo

A production-ready AWS Service Catalog demo for provisioning secure, encrypted S3 buckets with comprehensive security features. This infrastructure is fully managed by Terraform and can be completely created and destroyed.

## What This Creates

This Terraform module creates a complete AWS Service Catalog setup:

### Core Infrastructure
- **Service Catalog Portfolio**: Container for organizing products
- **Service Catalog Product**: Product definition for secure S3 buckets
- **IAM Roles**: 
  - Launch role (used by Service Catalog to provision resources)
  - End user role (for launching products)
- **CloudFormation Template**: Stored in S3 for Service Catalog to reference

### Security Features (S3 Buckets Provisioned Through Service Catalog)

When users launch a bucket through this Service Catalog product, they get:

1. **Encryption**: AWS-managed SSE-S3 (AES-256) default encryption
2. **Versioning**: Enabled by default to track object changes
3. **Public Access Block**: All four settings enabled to prevent public access
4. **HTTPS Enforcement**: Bucket policy denies non-HTTPS connections
5. **Lifecycle Management**: 
   - Transition to Standard-IA after configurable days (default: 30)
   - Transition to Glacier after configurable days (default: 90)
   - Expire old versions after configurable days (default: 90)
6. **Optional Access Logging**: When enabled, creates a dedicated logging bucket with 1-year log retention

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with permissions to create:
  - Service Catalog resources
  - IAM roles and policies
  - S3 buckets
  - CloudFormation templates

Required IAM permissions:
- `servicecatalog:*`
- `iam:*`
- `s3:*`
- `cloudformation:*`

## Usage

### Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Confirm with 'yes'
```

### Launch an S3 Bucket

After deployment, you can launch a secure S3 bucket through the AWS Service Catalog:

1. Navigate to **AWS Service Catalog** in the AWS Console
2. Find the portfolio named "Secure S3 Bucket Portfolio"
3. Click on the "Secure S3 Bucket" product
4. Click **"Launch"**
5. Fill in the parameters:
   - **BucketNamePrefix**: Your chosen prefix (e.g., `myapp-data`)
   - **EnableLogging**: Set to `true` to enable access logging
   - **Lifecycle Transition Days**: Configure when to transition to cheaper storage classes
   - **Expiration Days**: Configure when to delete old versions
   - **Tags**: Application, Environment, Owner
6. Click **"Launch"**

The bucket will be provisioned with all security features automatically configured.

### Example: Using AWS CLI

You can also launch products via CLI:

```bash
# Assume the end user role
aws sts assume-role --role-arn <end_user_role_arn> --role-session-name demo

# Launch a product
aws servicecatalog provision-product \
  --product-id <product_id> \
  --provisioned-product-name my-secure-bucket \
  --path-id <portfolio_id> \
  --provisioning-artifact-id <artifact_id> \
  --provisioning-parameters \
    Key=BucketNamePrefix,Value=myapp-bucket \
    Key=EnableLogging,Value=true \
    Key=Application,Value=myapp \
    Key=Environment,Value=production
```

### Destroy Everything

```bash
# Destroy all provisioned Service Catalog products first
aws servicecatalog list-provisioned-products | grep ProvisionedProductName

# Terminate each provisioned product
aws servicecatalog terminate-provisioned-product --provisioned-product-id <id>

# Then destroy the Terraform infrastructure
terraform destroy

# Confirm with 'yes'
```

## Configuration Variables

Customize the deployment via `variables.tf`:

- `portfolio_name`: Name of the Service Catalog portfolio (default: "Secure S3 Bucket Portfolio")
- `product_name`: Name of the Service Catalog product (default: "Secure S3 Bucket")
- `product_version`: Version of the product (default: "1.0")
- `lifecycle_ia_transition_days`: Days until transition to Standard-IA (default: 30)
- `lifecycle_glacier_transition_days`: Days until transition to Glacier (default: 90)
- `lifecycle_expiration_days`: Days until old versions expire (default: 90)
- `tags`: Common tags to apply to all resources

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Service Catalog Portfolio                         │
│  ┌───────────────────────────────────────────────┐ │
│  │  Secure S3 Bucket Product                     │ │
│  │  (CloudFormation Template)                    │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Launch
                  ▼
┌─────────────────────────────────────────────────────┐
│  End User Role                                      │
│  - Launch products from Service Catalog             │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│  Launch Role                                        │
│  - Provision S3 buckets with security features      │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│  S3 Bucket Resources                                │
│  - Encryption (SSE-S3)                               │
│  - Versioning                                        │
│  - Public Access Block                               │
│  - HTTPS Enforcement                                │
│  - Lifecycle Rules                                  │
│  - Optional Logging Bucket                          │
└─────────────────────────────────────────────────────┘
```

## Outputs

After running `terraform apply`, you'll get:

- `portfolio_id`: Service Catalog Portfolio ID
- `portfolio_arn`: Service Catalog Portfolio ARN
- `product_id`: Service Catalog Product ID
- `product_name`: Service Catalog Product Name
- `launch_role_arn`: IAM role used by Service Catalog to launch products
- `end_user_role_arn`: IAM role for end users to launch products
- `launch_instructions`: Detailed instructions for launching a bucket
- `cloudformation_template_s3_url`: S3 URL of the template

## Security Best Practices

This demo implements AWS security best practices:

1. **Default Encryption**: All buckets encrypted with SSE-S3
2. **Versioning**: Track all object changes
3. **Public Access Block**: Prevent accidental public exposure
4. **HTTPS Enforcement**: Deny insecure connections via bucket policy
5. **Lifecycle Rules**: Automatically optimize storage costs
6. **Access Logging**: Track all requests (optional, separate bucket per main bucket)
7. **Least Privilege IAM**: Roles have minimum required permissions

## Cost Considerations

The CloudFormation template S3 bucket is created to store the template and has minimal cost impact. When you launch S3 buckets through Service Catalog, they incur standard S3 costs:

- Standard storage: $0.023 per GB/month
- Standard-IA storage: $0.0125 per GB/month (after transition)
- Glacier storage: $0.004 per GB/month (after transition)
- Requests: Pay per request

Lifecycle rules help optimize costs by automatically transitioning to cheaper storage classes.

## Troubleshooting

### "Insufficient permissions" when launching
- Ensure the end user role has `servicecatalog:*` permissions
- Verify portfolio access is granted to the role

### Bucket creation fails
- Check the launch role has `s3:CreateBucket` and other S3 permissions
- Review CloudFormation stack events in the AWS Console

### Template upload fails
- Verify S3 bucket creation permissions
- Check bucket public access block configuration

## License

See LICENSE file for details.

## Contributing

Contributions welcome! Please ensure your changes maintain the security posture and follow Terraform best practices.
