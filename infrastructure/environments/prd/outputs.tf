# --- S3 + CloudFront ---

output "web_s3_bucket_name" {
  value       = module.this.web_s3_bucket_name
  description = "웹 S3 버킷 이름"
}

output "cloudfront_distribution_id" {
  value       = module.this.cloudfront_distribution_id
  description = "CloudFront Distribution ID"
}

output "deployment_commands" {
  value       = module.this.deployment_commands
  description = "웹 배포 명령어"
}
