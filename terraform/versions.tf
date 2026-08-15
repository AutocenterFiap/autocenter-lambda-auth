terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto sugerido (descomente e ajuste para usar S3 + DynamoDB lock):
  # backend "s3" {
  #   bucket         = "autocenter-tfstate"
  #   key            = "serverless-auth/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "autocenter-tflock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
