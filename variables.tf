variable "portfolio_name" {
  description = "Name of the Service Catalog portfolio"
  type        = string
  default     = "Secure S3 Bucket Portfolio"
}

variable "portfolio_description" {
  description = "Description of the Service Catalog portfolio"
  type        = string
  default     = "Portfolio for provisioning secure, encrypted S3 buckets with logging and lifecycle management"
}

variable "product_name" {
  description = "Name of the Service Catalog product"
  type        = string
  default     = "Secure S3 Bucket"
}

variable "product_description" {
  description = "Description of the Service Catalog product"
  type        = string
  default     = "Secure S3 bucket with encryption, versioning, lifecycle management, and optional logging"
}

variable "product_version" {
  description = "Version of the Service Catalog product"
  type        = string
  default     = "1.0"
}

variable "lifecycle_ia_transition_days" {
  description = "Days before transitioning objects to Standard-IA"
  type        = number
  default     = 30
}

variable "lifecycle_glacier_transition_days" {
  description = "Days before transitioning objects to Glacier"
  type        = number
  default     = 90
}

variable "lifecycle_expiration_days" {
  description = "Days before expiring old object versions"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "service-catalog-s3-demo"
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-2"
}
