locals {
  name = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "lambda" {
  name        = "${local.name}-sg"
  description = "Security group da Lambda de autenticacao"
  vpc_id      = local.vpc_id

  egress {
    description = "Saida para o RDS e servicos"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "authorizer" {
  name        = "${local.name}-authorizer-sg"
  description = "Security group da Lambda authorizer"
  vpc_id      = local.vpc_id

  egress {
    description = "Saida geral"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  description              = "Acesso da Lambda de auth ao banco"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = local.rds_security_group_id
  source_security_group_id = aws_security_group.lambda.id
}

resource "aws_lambda_function" "auth" {
  function_name = local.name
  role          = var.lab_role_arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  image_config {
    command = ["auth_fn.handler.handler"]
  }

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST            = local.db_host
      DB_PORT            = tostring(var.db_port)
      DB_NAME            = local.db_name
      DB_USER            = local.db_user
      DB_CONNECT_TIMEOUT = tostring(var.db_connect_timeout)
      DB_PASSWORD        = var.db_password
      JWT_SECRET         = var.jwt_secret
      JWT_ISSUER         = var.jwt_issuer
      JWT_EXP_MINUTES    = tostring(var.jwt_exp_minutes)
    }
  }

  tags = local.tags
}

resource "aws_lambda_function" "authorizer" {
  function_name = "${local.name}-authorizer"
  role          = var.lab_role_arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  image_config {
    command = ["auth_fn.authorizer.handler"]
  }

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.authorizer.id]
  }

  environment {
    variables = {
      JWT_SECRET      = var.jwt_secret
      JWT_ISSUER      = var.jwt_issuer
      JWT_EXP_MINUTES = tostring(var.jwt_exp_minutes)
    }
  }

  tags = local.tags
}

resource "aws_lb" "app" {
  name                             = "${local.name}-app"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = local.private_subnet_ids
  security_groups                  = [aws_security_group.nlb.id]
  enable_cross_zone_load_balancing = true
  tags                             = local.tags
}

resource "aws_lb_target_group" "app" {
  name               = "${local.name}-app"
  port               = local.application_node_port
  protocol           = "TCP"
  target_type        = "instance"
  vpc_id             = local.vpc_id
  preserve_client_ip = false
  tags               = local.tags

  lifecycle {
    precondition {
      condition     = local.application_node_port != null
      error_message = "O Service da aplicacao precisa expor um NodePort."
    }
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = data.aws_eks_node_group.app.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}

resource "aws_security_group" "vpc_link" {
  name        = "${local.name}-vpc-link-sg"
  description = "Security group do VPC Link para o NLB interno"
  vpc_id      = local.vpc_id

  egress {
    description     = "Acesso ao listener do NLB interno"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  tags = local.tags
}

resource "aws_security_group" "nlb" {
  name        = "${local.name}-nlb-sg"
  description = "Security group do NLB interno"
  vpc_id      = local.vpc_id

  egress {
    description     = "Acesso ao NodePort do cluster"
    from_port       = local.application_node_port
    to_port         = local.application_node_port
    protocol        = "tcp"
    security_groups = [data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.application_node_port != null
      error_message = "O Service da aplicacao precisa expor um NodePort."
    }
  }
}

resource "aws_security_group_rule" "nlb_from_vpc_link" {
  type                     = "ingress"
  description              = "VPC Link acessa o listener do NLB interno"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nlb.id
  source_security_group_id = aws_security_group.vpc_link.id
}

resource "aws_security_group_rule" "cluster_from_nlb" {
  type                     = "ingress"
  description              = "NLB acessa o NodePort da aplicacao"
  from_port                = local.application_node_port
  to_port                  = local.application_node_port
  protocol                 = "tcp"
  security_group_id        = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.nlb.id
}

resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["authorization", "content-type"]
    allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins     = var.allowed_origins
  }

  tags = local.tags
}

resource "aws_apigatewayv2_integration" "auth" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_vpc_link" "app" {
  name               = "${local.name}-vpc-link"
  subnet_ids         = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_link.id]
  tags               = local.tags
}

resource "aws_apigatewayv2_integration" "app" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.app.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.app.id
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id                            = aws_apigatewayv2_api.http.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${local.name}-jwt"
}

resource "aws_apigatewayv2_route" "auth" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /auth"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_apigatewayv2_route" "oauth_token" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /v1/oauth/token"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "oauth_refresh" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "POST /v1/oauth/refresh-token"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "protected" {
  api_id             = aws_apigatewayv2_api.http.id
  route_key          = "ANY /{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags
}

resource "aws_lambda_permission" "api_auth" {
  statement_id  = "AllowApiGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_authorizer" {
  statement_id  = "AllowApiGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt.id}"
}
