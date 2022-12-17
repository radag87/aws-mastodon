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

variable "registered_domain" {
  description = "The name of the domain that is to be used for this application (make sure you own this)"
  type        = string
}
