data "terraform_remote_state" "infraestrutura" {
  backend = "remote"

  config = {
    organization = "autocenter-fiap"
    workspaces = {
      name = "infraestrutura"
    }
  }
}

data "terraform_remote_state" "database" {
  backend = "remote"

  config = {
    organization = "autocenter-fiap"
    workspaces = {
      name = "database"
    }
  }
}

data "terraform_remote_state" "aplicacao" {
  backend = "remote"

  config = {
    organization = "autocenter-fiap"
    workspaces = {
      name = "aplicacao"
    }
  }
}

locals {
  infraestrutura_outputs = data.terraform_remote_state.infraestrutura.outputs
  database_outputs       = data.terraform_remote_state.database.outputs
  aplicacao_outputs      = data.terraform_remote_state.aplicacao.outputs

  vpc_id                   = try(local.infraestrutura_outputs.vpc_id, var.vpc_id)
  private_subnet_ids       = try(local.infraestrutura_outputs.private_subnet_ids, var.private_subnet_ids)
  rds_security_group_id    = try(local.database_outputs.rds_security_group_id, var.rds_security_group_id)
  eks_cluster_name         = try(local.infraestrutura_outputs.eks_cluster_name, var.eks_cluster_name)
  eks_node_group_name      = try(local.infraestrutura_outputs.eks_node_group_name, var.eks_node_group_name)
  db_host                  = try(local.database_outputs.rds_endpoint, var.db_host)
  db_name                  = try(local.database_outputs.db_name, var.db_name)
  db_user                  = try(local.database_outputs.db_user, var.db_user)
  application_service_name = try(local.aplicacao_outputs.application_service_name, var.application_service_name)
  application_namespace    = try(local.aplicacao_outputs.application_namespace, var.application_namespace)
}

data "aws_eks_cluster" "cluster" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

data "aws_eks_node_group" "app" {
  cluster_name    = local.eks_cluster_name
  node_group_name = local.eks_node_group_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "kubernetes_service" "application" {
  metadata {
    name      = local.application_service_name
    namespace = local.application_namespace
  }
}

locals {
  application_node_port = try(data.kubernetes_service.application.spec[0].port[0].node_port, null)
}

resource "terraform_data" "application_node_port_guard" {
  input = local.application_node_port

  lifecycle {
    precondition {
      condition     = local.application_node_port != null
      error_message = "O Service da aplicacao precisa expor um NodePort."
    }
  }
}
