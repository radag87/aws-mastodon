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
}

# see https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest for reference
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

  # One NAT Gateway per subnet 
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = local.tags
}
