-- ============================================================================
-- Usuário somente-leitura para a Function Serverless de autenticação.
--
-- A Lambda conecta no MESMO banco da aplicação principal, mas com privilégio
-- mínimo: só precisa ler a tabela `clientes`. Rode este script no RDS (com um
-- usuário administrativo) para criar o usuário usado pela Lambda.
--
-- Ajuste a senha e, se possível, restrinja o host (@'%') à faixa da VPC.
-- Guarde a senha no AWS Secrets Manager (referenciada por db_password_secret_arn).
-- ============================================================================

CREATE USER IF NOT EXISTS 'auth_readonly'@'%' IDENTIFIED BY 'TROQUE_ESTA_SENHA';

-- Privilégio mínimo: apenas SELECT na tabela de clientes do banco do app.
GRANT SELECT ON autocenterdb.clientes TO 'auth_readonly'@'%';

FLUSH PRIVILEGES;
