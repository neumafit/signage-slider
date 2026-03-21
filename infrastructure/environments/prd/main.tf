terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "neumafit-terraform-state"
    key    = "signage-slider/prd/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "this" {
  source = "../../modules/signage-slider"

  environment      = var.environment
  hosted_zone_name = var.hosted_zone_name
  web_domain       = var.web_domain
}
