terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.66.0"
    }
  }

  backend {
//    bucket = "vilarinho-state"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1" 

  default_tags {
    tags = {
      Application = "base"
      Group = "terraform-managed"
    }
  }
}
