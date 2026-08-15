import jwt

from auth_fn import jwt_service
from auth_fn.config import Config

CONFIG = Config(
    jwt_secret="segredo-de-teste",
    jwt_issuer="Auto Center Fiap",
    jwt_exp_minutes=30,
    db_host="", db_port=0, db_name="", db_user="", db_password="", db_connect_timeout=1,
)


def test_token_gerado_e_verificavel_como_no_app():
    token, expira = jwt_service.gerar_token(CONFIG, "12345678909", 1, "João da Silva")

    # Simula a verificação do app principal: HS256 + issuer
    decoded = jwt.decode(
        token,
        CONFIG.jwt_secret,
        algorithms=["HS256"],
        issuer="Auto Center Fiap",
    )

    assert decoded["sub"] == "12345678909"
    assert decoded["iss"] == "Auto Center Fiap"
    assert decoded["tipo"] == "cliente"
    assert decoded["clienteId"] == 1
    assert decoded["exp"] == expira


def test_token_invalido_com_secret_errado():
    token, _ = jwt_service.gerar_token(CONFIG, "12345678909", 1, "João")
    try:
        jwt.decode(token, "secret-errado", algorithms=["HS256"], issuer="Auto Center Fiap")
        assert False, "deveria ter falhado a verificação"
    except jwt.InvalidTokenError:
        pass
