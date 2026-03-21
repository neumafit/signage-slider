data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Secrets Manager ---

resource "aws_secretsmanager_secret" "deploy_config" {
  name = "/neumafit/signage-slider/${var.environment}"
}

resource "aws_secretsmanager_secret_version" "deploy_config_initial" {
  secret_id = aws_secretsmanager_secret.deploy_config.id
  secret_string = jsonencode({
    ACM_CERTIFICATE_ARN = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Read existing secret (ACM_CERTIFICATE_ARN 등 수동 설정값)
data "aws_secretsmanager_secret_version" "deploy_config" {
  secret_id  = aws_secretsmanager_secret.deploy_config.id
  depends_on = [aws_secretsmanager_secret_version.deploy_config_initial]
}

locals {
  secret_values = jsondecode(data.aws_secretsmanager_secret_version.deploy_config.secret_string)
}

# --- S3 + CloudFront ---

module "web_deployment" {
  source = "github.com/neumafit/terraform-aws-s3-cloudfront-deployment"

  hosted_zone_name    = var.hosted_zone_name
  domain              = var.web_domain
  acm_certificate_arn = local.secret_values["ACM_CERTIFICATE_ARN"]
  s3_bucket_name      = "neumafit-signage-slider-web-${var.environment}"
  default_root_object = "index.html"
}

# Merge Terraform outputs back into secret
resource "aws_secretsmanager_secret_version" "deploy_config" {
  secret_id = aws_secretsmanager_secret.deploy_config.id
  secret_string = jsonencode(merge(
    local.secret_values,
    {
      S3_BUCKET                  = "neumafit-signage-slider-web-${var.environment}"
      CLOUDFRONT_DISTRIBUTION_ID = module.web_deployment.cloudfront_distribution_id
    }
  ))
}
