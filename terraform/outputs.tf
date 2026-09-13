output "auth_endpoint" {
  description = "URL completa do endpoint de autenticação."
  value       = "${aws_apigatewayv2_api.http.api_endpoint}/auth"
}

output "api_endpoint" {
  description = "Base URL do HTTP API."
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "lambda_function_name" {
  description = "Nome da Lambda de autenticacao."
  value       = aws_lambda_function.auth.function_name
}

output "lambda_function_arn" {
  description = "ARN da Lambda de autenticacao."
  value       = aws_lambda_function.auth.arn
}

output "authorizer_function_name" {
  description = "Nome da Lambda authorizer JWT."
  value       = aws_lambda_function.authorizer.function_name
}

output "authorizer_function_arn" {
  description = "ARN da Lambda authorizer JWT."
  value       = aws_lambda_function.authorizer.arn
}

output "lambda_security_group_id" {
  description = "Security group da Lambda (usado no ingress do RDS)."
  value       = aws_security_group.lambda.id
}

output "internal_nlb_dns_name" {
  description = "DNS interno do NLB usado exclusivamente pela integracao VPC Link."
  value       = aws_lb.app.dns_name
}
