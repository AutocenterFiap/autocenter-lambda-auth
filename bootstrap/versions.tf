terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Bootstrap usa estado LOCAL de propósito: ele cria o próprio bucket de estado
  # remoto usado pelo módulo principal. Guarde o terraform.tfstate deste diretório
  # com cuidado (ou migre para o bucket depois de criado).
}

provider "aws" {
  region = var.aws_region
}
