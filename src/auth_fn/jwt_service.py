"""Geração de JWT compatível com o app principal (Auto Center FIAP).

O app verifica com HMAC256 (HS256) + issuer "Auto Center Fiap". Aqui geramos
o mesmo formato, com subject = CPF e claim `tipo=cliente` para distinguir dos
tokens de usuário interno.
"""
from datetime import datetime, timedelta, timezone

import jwt

from .config import Config


def gerar_token(config: Config, cpf: str, cliente_id: int, nome: str) -> tuple[str, int]:
    """Gera o token JWT. Retorna (token, expiracao_epoch_segundos)."""
    agora = datetime.now(timezone.utc)
    expira = agora + timedelta(minutes=config.jwt_exp_minutes)

    payload = {
        "iss": config.jwt_issuer,
        "sub": cpf,
        "tipo": "cliente",
        "clienteId": cliente_id,
        "nome": nome,
        "iat": int(agora.timestamp()),
        "exp": int(expira.timestamp()),
    }

    token = jwt.encode(payload, config.jwt_secret, algorithm="HS256")
    return token, int(expira.timestamp())
