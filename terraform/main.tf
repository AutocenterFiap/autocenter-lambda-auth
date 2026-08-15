locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ----------------------------------------------------------------------------
# Segredos (Secrets Manager) — lidos para injetar como variáveis de ambiente.
# Os secrets são criados fora deste módulo (ou manualmente); aqui só referenciamos.
# ----------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "jwt" {
  secret_id = var.jwt_secret_arn
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

# ----------------------------------------------------------------------------
# IAM — role de execução da Lambda
# ----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}

# Logs no CloudWatch + criação de ENIs na VPC (necessário para acessar o RDS)
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ----------------------------------------------------------------------------
# Rede — security group da Lambda e liberação de acesso ao RDS
# ----------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "${local.name}-sg"
  description = "Security group da Lambda de autenticacao"
  vpc_id      = var.vpc_id

  egress {
    description = "Saida para o RDS e AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Libera a Lambda a conectar na porta do banco no security group do RDS
resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  description              = "Acesso da Lambda de auth ao banco"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = aws_security_group.lambda.id
}

# ----------------------------------------------------------------------------
# Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "auth" {
  function_name    = local.name
  role             = aws_iam_role.lambda.arn
  runtime          = var.python_runtime
  handler          = "auth_fn.handler.handler"
  filename         = var.lambda_package
  source_code_hash = filebase64sha256(var.lambda_package)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST         = var.db_host
      DB_PORT         = tostring(var.db_port)
      DB_NAME         = var.db_name
      DB_USER         = var.db_user
      DB_PASSWORD     = data.aws_secretsmanager_secret_version.db_password.secret_string
      JWT_SECRET      = data.aws_secretsmanager_secret_version.jwt.secret_string
      JWT_ISSUER      = var.jwt_issuer
      JWT_EXP_MINUTES = tostring(var.jwt_exp_minutes)
    }
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 14
  tags              = local.tags
}

# ----------------------------------------------------------------------------
# API Gateway (HTTP API) — POST /auth -> Lambda (proxy)
# ----------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "auth" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.responseLatency"
    })
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
