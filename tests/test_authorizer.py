from datetime import datetime, timedelta, timezone

import jwt
import pytest

from auth_fn import authorizer, jwt_service
from auth_fn.config import AuthorizerConfig

CONFIG = AuthorizerConfig(
    jwt_secret="segredo-de-teste",
    jwt_issuer="Auto Center Fiap",
    jwt_exp_minutes=30,
)


@pytest.mark.parametrize("header_name", ["authorization", "Authorization"])
def test_authorizer_accepts_valid_hs256_token(monkeypatch, header_name):
    token, _ = jwt_service.gerar_token(CONFIG, "11144477735", 1, "João")
    monkeypatch.setattr(authorizer, "get_config", lambda: CONFIG)

    response = authorizer.handler({"headers": {header_name: f"Bearer {token}"}}, None)

    assert response == {"isAuthorized": True}


def test_authorizer_rejects_missing_authorization_header():
    assert authorizer.handler({"headers": {}}, None) == {"isAuthorized": False}


def test_authorizer_rejects_token_signed_with_wrong_secret(monkeypatch):
    wrong_config = AuthorizerConfig(
        jwt_secret="outro-segredo",
        jwt_issuer=CONFIG.jwt_issuer,
        jwt_exp_minutes=CONFIG.jwt_exp_minutes,
    )
    token, _ = jwt_service.gerar_token(wrong_config, "11144477735", 1, "João")
    monkeypatch.setattr(authorizer, "get_config", lambda: CONFIG)

    response = authorizer.handler({"headers": {"authorization": f"Bearer {token}"}}, None)

    assert response == {"isAuthorized": False}


def test_authorizer_rejects_token_with_wrong_issuer(monkeypatch):
    wrong_issuer_config = AuthorizerConfig(
        jwt_secret=CONFIG.jwt_secret,
        jwt_issuer="Outro Emissor",
        jwt_exp_minutes=CONFIG.jwt_exp_minutes,
    )
    token, _ = jwt_service.gerar_token(wrong_issuer_config, "11144477735", 1, "João")
    monkeypatch.setattr(authorizer, "get_config", lambda: CONFIG)

    response = authorizer.handler({"headers": {"authorization": f"Bearer {token}"}}, None)

    assert response == {"isAuthorized": False}


def test_authorizer_rejects_expired_token(monkeypatch):
    expired_token = jwt.encode(
        {
            "iss": CONFIG.jwt_issuer,
            "sub": "11144477735",
            "tipo": "cliente",
            "clienteId": 1,
            "nome": "João",
            "iat": int((datetime.now(timezone.utc) - timedelta(hours=1)).timestamp()),
            "exp": int((datetime.now(timezone.utc) - timedelta(minutes=1)).timestamp()),
        },
        CONFIG.jwt_secret,
        algorithm="HS256",
    )
    monkeypatch.setattr(authorizer, "get_config", lambda: CONFIG)

    response = authorizer.handler({"headers": {"authorization": f"Bearer {expired_token}"}}, None)

    assert response == {"isAuthorized": False}


def test_authorizer_rejects_token_without_exp(monkeypatch):
    token_without_exp = jwt.encode(
        {
            "iss": CONFIG.jwt_issuer,
            "sub": "11144477735",
            "tipo": "cliente",
            "clienteId": 1,
            "nome": "João",
            "iat": int(datetime.now(timezone.utc).timestamp()),
        },
        CONFIG.jwt_secret,
        algorithm="HS256",
    )
    monkeypatch.setattr(authorizer, "get_config", lambda: CONFIG)

    response = authorizer.handler({"headers": {"authorization": f"Bearer {token_without_exp}"}}, None)

    assert response == {"isAuthorized": False}


def test_authorizer_rejects_malformed_authorization_header():
    assert authorizer.handler({"headers": {"authorization": "token-sem-bearer"}}, None) == {
        "isAuthorized": False
    }
