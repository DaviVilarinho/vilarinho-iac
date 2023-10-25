terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "vilarinho-state"
    region = "us-east-1"
    key    = "vilarinho-iac"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Application = "base"
      Group       = "terraform-managed"
    }
  }
}

