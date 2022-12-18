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
  efs_backups = var.enable_efs_backups == true ? "ENABLED" : "DISABLED"
}

#
# networking
# this section of the config builds the network the application runs in
# 

# referenece https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = "${var.application}-${var.environment}"
  cidr = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  # One NAT Gateway per subnet 
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  tags = local.tags
}

#
# s3
# this section of the config is responsible for the creation of two resources
# * the s3 logging bucket (optional but defaults to true)
# * the s3 bucket that is used by mastodon to store uploads
#

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "log_bucket" {
  count               = var.enable_bucket_logging ? 1 : 0
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
  count  = var.enable_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  acl    = "log-delivery-write"
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  count                 = var.enable_bucket_logging ? 1 : 0
  bucket                = aws_s3_bucket.log_bucket[0].id
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  count  = var.enable_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# reference https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  count  = var.enable_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
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
  count                   = var.enable_bucket_logging ? 1 : 0
  bucket                  = aws_s3_bucket.log_bucket[0].id
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
  count         = var.enable_bucket_logging ? 1 : 0
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

#
# efs
# this section of the config is responsible for the creation of the file system that is used 
# by the mastodon service
#

resource "aws_efs_file_system" "efs" {
  creation_token   = "${var.application}-${var.environment}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(local.tags,
    {
      Name = "${var.application}-${var.environment}"
    }
  )
}

resource "aws_efs_backup_policy" "efs_backup" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = local.efs_backups
  }
}

resource "aws_efs_access_point" "efs_ap" {
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0644"
    }
    path = "/mastodon_data"
  }
}

data "aws_iam_policy_document" "efs_policy_doc" {
  statement {
    sid = "AllowEFSAccess"

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.efs.arn
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}


resource "aws_efs_file_system_policy" "policy" {
  file_system_id                     = aws_efs_file_system.efs.id
  bypass_policy_lockout_safety_check = false
  policy                             = data.aws_iam_policy_document.efs_policy_doc.json
}

resource "aws_efs_replication_configuration" "efs_replica" {
  count                 = length(var.efs_replica_region) == 0 ? 0 : 1
  source_file_system_id = aws_efs_file_system.efs.id

  destination {
    region = var.efs_replica_region
  }
}
