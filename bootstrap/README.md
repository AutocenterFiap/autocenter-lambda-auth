# Bootstrap — pré-requisitos de deploy (rodar UMA vez)

Este módulo cria a base para o CI/CD conseguir deployar a Lambda:

- **Bucket S3** (versionado + criptografado) para o estado do Terraform
- **Tabela DynamoDB** para lock do estado
- **OIDC provider** do GitHub Actions
- **IAM Role de deploy** que o GitHub assume via OIDC (restrita a este repo e aos
  ambientes `homolog`/`prod`), com as permissões para provisionar a Lambda

> É aplicado **manualmente**, uma única vez, por alguém com permissão de admin na
> conta AWS. Usa estado **local** (ele mesmo cria o backend remoto usado pelo resto).

## Como aplicar

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # preencha (bucket precisa ser único!)
terraform init
terraform apply
```

## Depois de aplicar

Os outputs viram a configuração do GitHub. Cadastre no repositório
(por ambiente, quando aplicável):

| Output | Onde usar no GitHub |
|---|---|
| `deploy_role_arn` | Secret `AWS_DEPLOY_ROLE_ARN` |
| `state_bucket` | Variable `TF_STATE_BUCKET` |
| `lock_table` | Variable `TF_LOCK_TABLE` |

```bash
gh secret set AWS_DEPLOY_ROLE_ARN --env homolog --repo AutocenterFiap/autocenter-lambda-auth
gh variable set TF_STATE_BUCKET --env homolog --body "<state_bucket>" --repo AutocenterFiap/autocenter-lambda-auth
gh variable set TF_LOCK_TABLE   --env homolog --body "<lock_table>"   --repo AutocenterFiap/autocenter-lambda-auth
# repita com --env prod
```

## Observações

- Se o **OIDC provider do GitHub já existir** na conta (outros repos costumam criar),
  rode com `create_oidc_provider = false` e informe `existing_oidc_provider_arn`.
- A política da role é ampla por serviço para simplificar; restrinja `secret_arns`
  aos ARNs reais e, se quiser, feche as permissões por recurso depois.
- O estado remoto é separado por ambiente: o CI usa a key
  `serverless-auth/<homolog|prod>/terraform.tfstate` no mesmo bucket.
