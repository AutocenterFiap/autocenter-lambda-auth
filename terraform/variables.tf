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
# Pacote da Lambda (gerado por scripts/build.sh -> dist/function.zip)
# ----------------------------------------------------------------------------
variable "lambda_package" {
  description = "Caminho para o zip da função."
  type        = string
  default     = "../dist/function.zip"
}

variable "python_runtime" {
  description = "Runtime Python da Lambda."
  type        = string
  default     = "python3.12"
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
}

variable "private_subnet_ids" {
  description = "Subnets privadas com rota para o RDS."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group do RDS — receberá regra de ingress vinda da Lambda."
  type        = string
}

# ----------------------------------------------------------------------------
# Banco de dados (RDS) — endpoint fornecido pelo repo de infra de banco
# ----------------------------------------------------------------------------
variable "db_host" {
  description = "Endpoint do RDS."
  type        = string
}

variable "db_port" {
  description = "Porta do banco."
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Nome do banco."
  type        = string
  default     = "autocenterdb"
}

variable "db_user" {
  description = "Usuário do banco (somente leitura recomendado)."
  type        = string
}

variable "db_password_secret_arn" {
  description = "ARN do secret (Secrets Manager) com a senha do banco."
  type        = string
}

# ----------------------------------------------------------------------------
# JWT — o secret DEVE ser o mesmo do app principal para o token ser aceito
# ----------------------------------------------------------------------------
variable "jwt_secret_arn" {
  description = "ARN do secret (Secrets Manager) com a chave HMAC do JWT (mesma do app)."
  type        = string
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
