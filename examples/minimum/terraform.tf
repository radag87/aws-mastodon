terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    http = ">= 1.1.1"
  }

  required_version = ">= 1.2.0"

  #   backend "s3" {
  #     dynamodb_table = "lock-table-name"
  #     bucket         = "tfstate-bucket-name"
  #     key            = "myapp/terraform.tfstate"
  #     region         = "us-east-1"
  #     encrypt        = true
  #   }
}
