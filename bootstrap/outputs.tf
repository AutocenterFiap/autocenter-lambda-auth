output "deploy_role_arn" {
  description = "ARN da role de deploy → secret AWS_DEPLOY_ROLE_ARN no GitHub."
  value       = aws_iam_role.deploy.arn
}

output "state_bucket" {
  description = "Bucket S3 do estado → var TF_STATE_BUCKET no GitHub."
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table" {
  description = "Tabela DynamoDB de lock → var TF_LOCK_TABLE no GitHub."
  value       = aws_dynamodb_table.tflock.name
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider do GitHub Actions."
  value       = local.oidc_provider_arn
}
