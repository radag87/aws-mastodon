provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

data "http" "ip_address" {
  url = "https://ifconfig.me/ip"
}

locals {
  tags = merge(var.tags,
    {
      terraform   = "true"
      environment = var.environment
      expense     = var.expense
      application = var.application
    }
  )
  server_name = "${var.application}-${var.environment}-builder"
  s3 = {
    bucket     = lower("${var.application}-${var.aws_region}-${var.environment}")
    log_bucket = lower("${var.application}-${var.aws_region}-${var.environment}-access-logs")
    log_prefix = lower("${var.application}-${var.aws_region}-${var.environment}-log/")
  }
}

# referenece https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = "${var.application}-${var.environment}"
  cidr = var.vpc_cidr

  azs                   = var.azs
  private_subnets       = var.private_subnets
  private_subnet_suffix = "private"
  public_subnets        = var.public_subnets
  public_subnet_suffix  = "public"
  database_subnets = var.database_subnets
  database_subnet_suffix = "database"

  # One NAT Gateway per subnet 
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = local.tags
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket              = local.s3.log_bucket
  object_lock_enabled = true
  tags = merge(local.tags,
    {
      Name = local.s3.log_bucket
    }
  )
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket                = aws_s3_bucket.log_bucket.id
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id = "deleteAfter400days"

    filter {}

    expiration {
      days = 400
    }

    transition {
      storage_class = "INTELLIGENT_TIERING"
    }

    status = "Enabled"
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "log_bucket_blocks" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "bucket" {
  bucket = local.s3.bucket
  tags = merge(local.tags,
    {
      Name = local.s3.bucket
    },
  )
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket                = aws_s3_bucket.bucket.id
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    id = "intelligentTiering"

    filter {}

    transition {
      storage_class = "INTELLIGENT_TIERING"
    }

    status = "Enabled"
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging
resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = local.s3.log_bucket
  target_prefix = local.s3.log_prefix
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "bucket_blocks" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "bucket_owner" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
