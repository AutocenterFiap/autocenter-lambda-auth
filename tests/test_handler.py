import json

from auth_fn import handler
from auth_fn.errors import ClienteNaoEncontradoError

CPF_VALIDO = "12345678909"


def test_handler_sucesso(monkeypatch):
    monkeypatch.setattr(handler, "autenticar", lambda cfg, cpf: {"token": "abc", "clienteId": 1})

    resp = handler.handler({"body": json.dumps({"cpf": CPF_VALIDO})}, None)

    assert resp["statusCode"] == 200
    assert json.loads(resp["body"])["token"] == "abc"


def test_handler_erro_de_negocio(monkeypatch):
    def _raise(cfg, cpf):
        raise ClienteNaoEncontradoError()

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

    monkeypatch.setattr(handler, "autenticar", _raise)

    resp = handler.handler({"body": json.dumps({"cpf": CPF_VALIDO})}, None)

    assert resp["statusCode"] == 500
    assert json.loads(resp["body"])["erro"] == "ERRO_INTERNO"
