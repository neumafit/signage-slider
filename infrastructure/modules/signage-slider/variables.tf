variable "environment" {
  type        = string
  description = "배포 환경 (dev, stg, prd)"
}

# --- 웹 배포 (S3 + CloudFront) ---

variable "hosted_zone_name" {
  type        = string
  description = "Route53 호스팅 존 이름"
}

variable "web_domain" {
  type        = string
  description = "웹 프론트엔드 도메인"
}
