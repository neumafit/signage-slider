# --- S3 + CloudFront ---

output "web_s3_bucket_name" {
  value       = "neumafit-signage-slider-web-${var.environment}"
  description = "웹 S3 버킷 이름"
}

output "cloudfront_distribution_id" {
  value       = module.web_deployment.cloudfront_distribution_id
  description = "CloudFront Distribution ID"
}

output "deployment_commands" {
  value       = module.web_deployment.deployment_commands
  description = "웹 배포 명령어"
}
