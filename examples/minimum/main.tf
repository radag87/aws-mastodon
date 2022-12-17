provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "mastodon" {
  # source  = "radag87/aws-mastodon/aws"
  # version = "1.0.0"
  source           = "git::https://github.com/radag87/aws-mastodon.git?ref=master"
  registred_domain = var.registered_domain
}
