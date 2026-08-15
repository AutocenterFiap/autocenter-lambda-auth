variable "aws_region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "Org/usuário dono do repositório."
  type        = string
  default     = "AutocenterFiap"
}

variable "github_repo" {
  description = "Nome do repositório da Lambda."
  type        = string
  default     = "autocenter-lambda-auth"
}

variable "environments" {
  description = "Ambientes do GitHub autorizados a assumir a role de deploy."
  type        = list(string)
  default     = ["homolog", "prod"]
}

variable "state_bucket_name" {
  description = "Nome (globalmente único) do bucket S3 para o estado do Terraform."
  type        = string
}

variable "lock_table_name" {
  description = "Nome da tabela DynamoDB para lock do estado."
  type        = string
  default     = "autocenter-tflock"
}

variable "deploy_role_name" {
  description = "Nome da IAM role de deploy assumida pelo GitHub Actions."
  type        = string
  default     = "autocenter-lambda-auth-deploy"
}

variable "create_oidc_provider" {
  description = "Criar o OIDC provider do GitHub. Deixe false se já existir na conta."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN do OIDC provider existente (usado quando create_oidc_provider = false)."
  type        = string
  default     = ""
}

variable "secret_arns" {
  description = "ARNs dos secrets (JWT + senha do banco) que a role de deploy pode ler."
  type        = list(string)
  default     = ["*"]
}
