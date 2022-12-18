variable "aws_profile" {
  description = "The profile to use from the aws credentials and config files"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "The region in AWS where the resources should be deployed. Ideally there would be one tfvars file per region per environment"
  type        = string
  default     = "us-east-1"
}

variable "expense" {
  description = "The expense tag to add to the resources"
  type        = string
  default     = "myexpense"
}

variable "application" {
  description = "The application name to add to the resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "The environment to be deployed"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "The CIDR range for the entire VPC must encompass the subnet addresses"
  type        = string
  default     = "192.168.0.0/16"
}

variable "azs" {
  description = "The availability zones to create assets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "The CIDR ranges for the private subnets"
  type        = list(string)
  default     = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
}

variable "public_subnets" {
  description = "The CIDR ranges for the public subnets"
  type        = list(string)
  default     = ["192.168.11.0/24", "192.168.12.0/24", "192.168.13.0/24"]
}

variable "database_subnets" {
  description = "The CIDR ranges for the database subnets"
  type        = list(string)
  default     = ["192.168.21.0/24", "192.168.22.0/24", "192.168.23.0/24"]
}

variable "registered_domain" {
  description = "The name of the domain that is to be used for this application (make sure you own this)"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(any)
  default     = {}
}

variable "enable_bucket_logging" {
  description = "A toggle to deterine if bucket logging should be enabled (default is true)"
  type        = bool
  default     = true
}
