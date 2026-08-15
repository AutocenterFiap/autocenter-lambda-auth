# ADR 0001 — Runtime Python em AWS Lambda para a Function de autenticação

- **Status:** Aceito
- **Data:** 2026-08-15
- **Contexto do trabalho:** Tech Challenge Fase 3 (13SOAT) — Function Serverless

## Contexto

O desafio exige uma Function Serverless que valide o CPF do cliente, consulte a
base de dados e devolva um JWT para consumo das APIs protegidas. A aplicação
principal é escrita em Java (Spring Boot). A função está no caminho crítico do
login, portanto latência importa.

## Decisão

Implementar a função em **Python 3.12** sobre **AWS Lambda**, empacotada em zip e
provisionada via Terraform, com **API Gateway (HTTP API)** na frente.

## Alternativas consideradas

| Opção | Prós | Contras |
|---|---|---|
| **Java 21** (coerência com o app) | Reuso de `ValidadorCpf`/Auth0 JWT | Cold start alto (3–6s); exigiria SnapStart; pacote maior |
| **Node.js/TS** | Cold start baixo; ecossistema JWT | Mais uma linguagem no time |
| **Python 3.12** ✅ | Cold start baixo (~200–400ms); função pequena e legível; build/CI simples | Reimplementar validação de CPF (~30 linhas) |

## Consequências

- **Positivas:** menor latência a frio, pacote de deploy enxuto, pipeline de CI
  simples (`pip` + zip), iteração rápida.
- **Negativas / mitigadas:** lógica de CPF reescrita em Python (portada 1:1 e
  coberta por testes); linguagem diferente do restante do time — aceitável pois
  os 4 repositórios são independentes por design.
- **Interoperabilidade do JWT:** garantida por usar HS256 + mesmo secret + mesmo
  issuer que o app (ver [ADR 0002](0002-jwt-hmac-compartilhado.md)).
