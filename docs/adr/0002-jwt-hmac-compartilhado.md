# ADR 0002 — JWT HMAC com secret compartilhado

- **Status:** Aceito
- **Data:** 2026-08-15

## Contexto

O token emitido pela Lambda precisa ser aceito pelas APIs protegidas do app
principal sem que estas precisem chamar a Lambda a cada requisição (stateless).
O app hoje verifica tokens com **HMAC256 (HS256)** e `issuer = "Auto Center Fiap"`.

## Decisão

A Lambda assina o JWT com **HS256**, usando:
- o **mesmo secret** do app (armazenado no **AWS Secrets Manager**, injetado como
  variável de ambiente pela infra);
- `issuer = "Auto Center Fiap"`;
- `subject = CPF` do cliente;
- claim adicional `tipo = "cliente"` para distinguir de tokens de usuário interno.

## Alternativas consideradas

- **RS256 (par de chaves assimétrico):** mais seguro para múltiplos emissores
  (a Lambda assinaria com chave privada e o app validaria com a pública). Preterido
  por ora para não alterar o mecanismo de verificação já existente no app; fica
  registrado como evolução recomendada.
- **Autorizador JWT no próprio API Gateway:** validaria o token na borda. Pode ser
  adicionado depois; não conflita com esta decisão.

## Consequências

- **Positivas:** integração imediata com o app; verificação stateless; sem
  round-trip extra.
- **Negativas:** secret simétrico compartilhado entre serviços — exige rotação
  coordenada e guarda no Secrets Manager (nunca em texto plano no repositório).
- **Ação para o time do app:** o filtro de autenticação precisa aceitar tokens
  cujo `subject` é um CPF (claim `tipo=cliente`), além dos tokens de usuário.
