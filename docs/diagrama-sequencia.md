# Diagrama de Sequência — Autenticação por CPF

Fluxo completo desde a requisição do cliente até o consumo de uma API protegida.

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    participant GW as API Gateway
    participant L as Lambda (auth_fn)
    participant DB as RDS (clientes)
    participant API as API Protegida (app K8s)

    C->>GW: POST /auth { cpf }
    GW->>L: invoca (proxy)

    L->>L: valida CPF (dígitos verificadores)
    alt CPF inválido
        L-->>GW: 400 CPF_INVALIDO
        GW-->>C: 400
    else CPF válido
        L->>DB: SELECT id, nome, status WHERE documento = cpf
        alt Cliente não existe
            DB-->>L: (vazio)
            L-->>GW: 404 CLIENTE_NAO_ENCONTRADO
            GW-->>C: 404
        else Cliente existe
            DB-->>L: { id, nome, status }
            alt status != ATIVO
                L-->>GW: 403 CLIENTE_INATIVO
                GW-->>C: 403
            else status == ATIVO
                L->>L: gera JWT (HS256, iss=Auto Center Fiap, sub=cpf, tipo=cliente)
                L-->>GW: 200 { token, expiraEm }
                GW-->>C: 200 { token }
            end
        end
    end

    Note over C,API: Fluxo subsequente com o token

    C->>API: GET /rota-protegida (Authorization: Bearer <token>)
    API->>API: verifica JWT (mesmo secret + issuer)
    API-->>C: 200 dados
```

## Observações

- O JWT é assinado com o **mesmo secret e issuer** do app principal, então as
  APIs protegidas validam o token sem chamar a Lambda novamente (stateless).
- A claim `tipo=cliente` distingue o token de cliente dos tokens de usuário interno.
- A Lambda tem acesso **somente leitura** à tabela `clientes`.
