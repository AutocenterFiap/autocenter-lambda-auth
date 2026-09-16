import json

from auth_fn import handler
from auth_fn.config import Config
from auth_fn.errors import ClienteNaoEncontradoError

CPF_VALIDO = "12345678909"
CONFIG = Config(
    jwt_secret="segredo-de-teste",
    jwt_issuer="Auto Center Fiap",
    jwt_exp_minutes=30,
    db_host="", db_port=0, db_name="", db_user="", db_password="", db_connect_timeout=1,
)


def test_handler_sucesso(monkeypatch):
    monkeypatch.setattr(handler, "get_config", lambda: CONFIG)
    monkeypatch.setattr(handler, "autenticar", lambda cfg, cpf: {"token": "abc", "clienteId": 1})

    resp = handler.handler({"body": json.dumps({"cpf": CPF_VALIDO})}, None)

    assert resp["statusCode"] == 200
    assert json.loads(resp["body"])["token"] == "abc"


def test_handler_erro_de_negocio(monkeypatch):
    def _raise(cfg, cpf):
        raise ClienteNaoEncontradoError()

    monkeypatch.setattr(handler, "get_config", lambda: CONFIG)
    monkeypatch.setattr(handler, "autenticar", _raise)

    resp = handler.handler({"body": json.dumps({"cpf": CPF_VALIDO})}, None)

    assert resp["statusCode"] == 404
    assert json.loads(resp["body"])["erro"] == "CLIENTE_NAO_ENCONTRADO"


def test_handler_body_ausente():
    resp = handler.handler({}, None)
    assert resp["statusCode"] == 400
    assert json.loads(resp["body"])["erro"] == "CPF_INVALIDO"


def test_handler_body_json_invalido():
    resp = handler.handler({"body": "isso não é json"}, None)
    assert resp["statusCode"] == 400


def test_handler_erro_inesperado(monkeypatch):
    def _raise(cfg, cpf):
        raise RuntimeError("boom")

    monkeypatch.setattr(handler, "get_config", lambda: CONFIG)
    monkeypatch.setattr(handler, "autenticar", _raise)

    resp = handler.handler({"body": json.dumps({"cpf": CPF_VALIDO})}, None)

    assert resp["statusCode"] == 500
    assert json.loads(resp["body"])["erro"] == "ERRO_INTERNO"


def test_get_config_carrega_uma_vez_e_reutiliza_cache(monkeypatch):
    expected = Config(
        jwt_secret="cache-secret",
        jwt_issuer="Auto Center Fiap",
        jwt_exp_minutes=30,
        db_host="localhost",
        db_port=3306,
        db_name="autocenterdb",
        db_user="autocenter",
        db_password="db-password",
        db_connect_timeout=5,
    )
    calls = {"count": 0}

    def _load_config():
        calls["count"] += 1
        return expected

    monkeypatch.setattr(handler, "_config", None)
    monkeypatch.setattr(handler, "load_config", _load_config)

    first = handler.get_config()
    second = handler.get_config()

    assert first is expected
    assert second is expected
    assert calls["count"] == 1
