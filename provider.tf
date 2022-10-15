terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
    github = {
      source = "integrations/github"
      version = "5.5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

provider "github" {
  token = var.github_token #  PLEASE ENTER YOUR GITHUB TOKEN
}