variable "aws_region" {
  description = "Região AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo usado para nomear os recursos."
  type        = string
  default     = "autocenter-auth"
}

variable "environment" {
  description = "Ambiente (homolog, prod, etc.)."
  type        = string
  default     = "homolog"
}

# ----------------------------------------------------------------------------
# Imagem da Lambda publicada no ECR antes do apply remoto do Terraform Cloud
# ----------------------------------------------------------------------------
variable "lambda_image_uri" {
  description = "URI completa da imagem da Lambda publicada no ECR."
  type        = string

  validation {
    condition     = trimspace(var.lambda_image_uri) != ""
    error_message = "lambda_image_uri deve apontar para uma imagem publicada no ECR."
  }
}

variable "lambda_timeout" {
  description = "Timeout da Lambda em segundos."
  type        = number
  default     = 10
}

variable "lambda_memory" {
  description = "Memória da Lambda em MB."
  type        = number
  default     = 256
}

# ----------------------------------------------------------------------------
# Rede — a Lambda precisa estar na mesma VPC do RDS para acessá-lo
# ----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID da VPC onde o RDS está (fornecido pelo repo de infra de banco)."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Subnets privadas com rota para o RDS."
  type        = list(string)
  default     = null
}

variable "rds_security_group_id" {
  description = "Security group do RDS — receberá regra de ingress vinda da Lambda."
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "Nome do cluster EKS existente."
  type        = string
  default     = null
}

variable "application_service_name" {
  description = "Nome do Service Kubernetes existente da aplicacao."
  type        = string
  default     = null
}

variable "application_namespace" {
  description = "Namespace do Service Kubernetes existente da aplicacao."
  type        = string
  default     = null
}

variable "eks_node_group_name" {
  description = "Nome do node group EKS que recebera o NodePort."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Banco de dados (RDS) — endpoint fornecido pelo repo de infra de banco
# ----------------------------------------------------------------------------
variable "db_host" {
  description = "Endpoint do RDS."
  type        = string
  default     = null
}

variable "db_port" {
  description = "Porta do banco."
  type        = number
  default     = 3306
}

variable "db_connect_timeout" {
  description = "Timeout de conexão com o banco, em segundos."
  type        = number
  default     = 5
}

variable "db_name" {
  description = "Nome do banco."
  type        = string
  default     = "autocenterdb"
}

variable "db_user" {
  description = "Usuário do banco (somente leitura recomendado)."
  type        = string
  default     = null
}

variable "db_password" {
  description = "Senha do banco usada pela Lambda de autenticacao."
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------------
# JWT — o secret DEVE ser o mesmo do app principal para o token ser aceito
# ----------------------------------------------------------------------------
variable "jwt_secret" {
  description = "Chave HMAC compartilhada com o app principal."
  type        = string
  sensitive   = true
}

variable "jwt_issuer" {
  description = "Issuer do JWT (deve casar com o app)."
  type        = string
  default     = "Auto Center Fiap"
}

variable "jwt_exp_minutes" {
  description = "Expiração do token em minutos."
  type        = number
  default     = 30
}

variable "allowed_origins" {
  description = "Origens permitidas pelo CORS do HTTP API."
  type        = list(string)
  default     = ["*"]
}

variable "lab_role_arn" {
  description = "ARN do IAM Role existente para execucao (AWS Academy LabRole)."
  type        = string
  default     = "arn:aws:iam::698096482625:role/LabRole"
}
