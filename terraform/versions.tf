terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend remoto S3 + DynamoDB lock — configuração PARCIAL.
  # bucket/key/region/dynamodb_table são passados no `terraform init -backend-config=...`.
  # O CI usa uma KEY por ambiente (serverless-auth/<homolog|prod>/terraform.tfstate),
  # garantindo estados isolados entre homolog e prod.
  # Para rodar/validar localmente sem estado remoto: `terraform init -backend=false`.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
