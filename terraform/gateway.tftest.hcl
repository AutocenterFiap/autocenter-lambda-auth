mock_provider "aws" {}
mock_provider "kubernetes" {}

override_data {
  target = data.terraform_remote_state.infraestrutura
  values = {
    outputs = {
      vpc_id           = "vpc-remote"
      eks_cluster_name = "cluster-remote"
    }
  }
}

override_data {
  target = data.terraform_remote_state.database
  values = {
    outputs = {
      rds_endpoint = "db.remote.internal"
    }
  }
}

override_data {
  target = data.terraform_remote_state.aplicacao
  values = {
    outputs = {}
  }
}

override_data {
  target = data.aws_eks_cluster.cluster
  values = {
    endpoint = "https://cluster.example.invalid"
    certificate_authority = [{
      data = "Q0E="
    }]
    vpc_config = [{
      cluster_security_group_id = "sg-cluster"
    }]
  }
}

override_data {
  target = data.aws_eks_cluster_auth.cluster
  values = {
    token = "fake-token"
  }
}

override_data {
  target = data.aws_eks_node_group.app
  values = {
    resources = [{
      autoscaling_groups = [{
        name = "eks-app-asg"
      }]
    }]
  }
}

override_data {
  target = data.kubernetes_service.application
  values = {
    spec = [{
      port = [{
        node_port = 31011
      }]
    }]
  }
}

run "gateway_topology" {
  command = plan

  variables {
    vpc_id                   = "vpc-test"
    private_subnet_ids       = ["subnet-a", "subnet-b"]
    rds_security_group_id    = "sg-rds"
    db_host                  = "db.internal"
    lambda_image_uri         = "123456789012.dkr.ecr.us-east-1.amazonaws.com/autocenter-auth:sha-test"
    db_user                  = "auth"
    db_password              = "db-test-secret"
    jwt_secret               = "jwt-test-secret"
    eks_cluster_name         = "cluster"
    eks_node_group_name      = "app"
    application_service_name = "autocenter-app-service"
    application_namespace    = "autocenter"
    allowed_origins          = ["https://app.example.com"]
  }

  assert {
    condition     = aws_lb.app.internal
    error_message = "O balanceador da aplicacao deve ser interno."
  }

  assert {
    condition     = aws_lb_target_group.app.port == local.application_node_port
    error_message = "O target group deve usar o NodePort descoberto do Service Kubernetes."
  }

  assert {
    condition     = tostring(aws_lb_target_group.app.preserve_client_ip) == "false"
    error_message = "O target group deve desabilitar preserve_client_ip para o SG do NLB ser a origem observada pelo cluster."
  }

  assert {
    condition = (
      length([
        for rule in aws_security_group.nlb.egress : rule
        if rule.from_port == local.application_node_port &&
        rule.to_port == local.application_node_port &&
        rule.protocol == "tcp" &&
        length(rule.security_groups) == 1 &&
        contains(rule.security_groups, "sg-cluster")
      ]) == 1 &&
      aws_security_group_rule.cluster_from_nlb.from_port == local.application_node_port &&
      aws_security_group_rule.cluster_from_nlb.to_port == local.application_node_port &&
      aws_security_group_rule.cluster_from_nlb.security_group_id == "sg-cluster" &&
      try(length(aws_security_group_rule.cluster_from_nlb.cidr_blocks), 0) == 0
    )
    error_message = "O trafego para o NodePort deve sair do SG do NLB sem liberar CIDRs publicos."
  }

  assert {
    condition     = aws_apigatewayv2_route.protected.authorization_type == "CUSTOM"
    error_message = "A rota proxy deve exigir Lambda Authorizer."
  }

  assert {
    condition     = aws_apigatewayv2_route.auth.authorization_type == "NONE"
    error_message = "POST /auth nao pode exigir token."
  }

  assert {
    condition     = aws_apigatewayv2_route.oauth_token.authorization_type == "NONE"
    error_message = "POST /v1/oauth/token nao pode exigir token."
  }

  assert {
    condition     = aws_apigatewayv2_route.oauth_refresh.authorization_type == "NONE"
    error_message = "POST /v1/oauth/refresh-token nao pode exigir token."
  }

  assert {
    condition = (
      aws_lambda_function.auth.package_type == "Image" &&
      aws_lambda_function.authorizer.package_type == "Image" &&
      aws_lambda_function.auth.image_uri == var.lambda_image_uri &&
      aws_lambda_function.authorizer.image_uri == var.lambda_image_uri &&
      length(aws_lambda_function.auth.image_config) == 1 &&
      length(aws_lambda_function.authorizer.image_config) == 1 &&
      length(aws_lambda_function.auth.image_config[0].command) == 1 &&
      length(aws_lambda_function.authorizer.image_config[0].command) == 1 &&
      aws_lambda_function.auth.image_config[0].command[0] == "auth_fn.handler.handler" &&
      aws_lambda_function.authorizer.image_config[0].command[0] == "auth_fn.authorizer.handler"
    )
    error_message = "As Lambdas devem usar a mesma imagem ECR com comandos distintos para auth e authorizer."
  }

  assert {
    condition = (
      aws_apigatewayv2_authorizer.jwt.authorizer_type == "REQUEST" &&
      aws_apigatewayv2_authorizer.jwt.enable_simple_responses &&
      aws_apigatewayv2_authorizer.jwt.authorizer_payload_format_version == "2.0" &&
      length(aws_apigatewayv2_authorizer.jwt.identity_sources) == 1 &&
      contains(aws_apigatewayv2_authorizer.jwt.identity_sources, "$request.header.Authorization")
    )
    error_message = "O authorizer HTTP API deve ser REQUEST, simples e ler o header Authorization."
  }

  assert {
    condition = (
      contains(keys(aws_lambda_function.auth.environment[0].variables), "JWT_SECRET") &&
      contains(keys(aws_lambda_function.auth.environment[0].variables), "DB_PASSWORD") &&
      contains(keys(aws_lambda_function.auth.environment[0].variables), "JWT_ISSUER") &&
      contains(keys(aws_lambda_function.auth.environment[0].variables), "JWT_EXP_MINUTES") &&
      contains(keys(aws_lambda_function.auth.environment[0].variables), "DB_CONNECT_TIMEOUT") &&
      !contains(keys(aws_lambda_function.auth.environment[0].variables), "JWT_SECRET_ARN") &&
      !contains(keys(aws_lambda_function.auth.environment[0].variables), "DB_PASSWORD_SECRET_ARN") &&
      nonsensitive(aws_lambda_function.auth.environment[0].variables.JWT_SECRET) == nonsensitive(var.jwt_secret) &&
      nonsensitive(aws_lambda_function.auth.environment[0].variables.DB_PASSWORD) == nonsensitive(var.db_password) &&
      nonsensitive(aws_lambda_function.auth.environment[0].variables.DB_CONNECT_TIMEOUT) == tostring(var.db_connect_timeout)
    )
    error_message = "A Lambda deve receber os secrets diretamente por variáveis de ambiente."
  }

  assert {
    condition = (
      contains(keys(aws_lambda_function.authorizer.environment[0].variables), "JWT_SECRET") &&
      contains(keys(aws_lambda_function.authorizer.environment[0].variables), "JWT_ISSUER") &&
      contains(keys(aws_lambda_function.authorizer.environment[0].variables), "JWT_EXP_MINUTES") &&
      !contains(keys(aws_lambda_function.authorizer.environment[0].variables), "DB_PASSWORD") &&
      !contains(keys(aws_lambda_function.authorizer.environment[0].variables), "DB_HOST") &&
      !contains(keys(aws_lambda_function.authorizer.environment[0].variables), "JWT_SECRET_ARN") &&
      nonsensitive(aws_lambda_function.authorizer.environment[0].variables.JWT_SECRET) == nonsensitive(var.jwt_secret)
    )
    error_message = "O authorizer deve receber apenas configuração JWT."
  }

  assert {
    condition     = local.vpc_id == "vpc-remote"
    error_message = "A VPC precisa vir do remote state da infraestrutura."
  }

  assert {
    condition     = local.db_host == "db.remote.internal"
    error_message = "O endpoint do banco precisa vir do remote state do database."
  }

  assert {
    condition     = local.application_node_port == 31011
    error_message = "O NodePort da aplicacao precisa vir do Service Kubernetes existente."
  }

  assert {
    condition = (
      output.lambda_function_name == "${var.project_name}-${var.environment}" &&
      output.authorizer_function_name == "${var.project_name}-${var.environment}-authorizer"
    )
    error_message = "Os outputs devem expor os nomes esperados das Lambdas de auth e authorizer."
  }
}
