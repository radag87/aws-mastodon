output "caller_account" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets[*]
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets[*]
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "my_ip" {
  value = data.http.ip_address.response_body
}

output "s3_log_bucket_id" {
  value = var.enable_bucket_logging ? aws_s3_bucket.log_bucket[0].id : null
}

output "s3_log_bucket_arn" {
  value = var.enable_bucket_logging ? aws_s3_bucket.log_bucket[0].arn : null
}

output "s3_bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

