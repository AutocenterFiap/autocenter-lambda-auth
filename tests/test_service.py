import jwt
import pytest

from auth_fn import service
from auth_fn.config import Config
from auth_fn.errors import ClienteInativoError, ClienteNaoEncontradoError, CpfInvalidoError
from auth_fn.repository import Cliente

CONFIG = Config(
    jwt_secret="segredo-de-teste",
    jwt_issuer="Auto Center Fiap",
    jwt_exp_minutes=30,
    db_host="", db_port=0, db_name="", db_user="", db_password="", db_connect_timeout=1,
)

CPF_VALIDO = "12345678909"


def _mock_repo(monkeypatch, cliente):
    monkeypatch.setattr(service, "buscar_por_documento", lambda cfg, doc: cliente)


def test_autenticar_sucesso(monkeypatch):
    _mock_repo(monkeypatch, Cliente(id=7, nome="Maria", status="ATIVO"))

    resultado = service.autenticar(CONFIG, "123.456.789-09")

    assert resultado["clienteId"] == 7
    assert resultado["tokenType"] == "Bearer"
    decoded = jwt.decode(resultado["token"], CONFIG.jwt_secret, algorithms=["HS256"], issuer="Auto Center Fiap")
    assert decoded["sub"] == CPF_VALIDO


def test_autenticar_cpf_invalido(monkeypatch):
    _mock_repo(monkeypatch, Cliente(id=1, nome="X", status="ATIVO"))
    with pytest.raises(CpfInvalidoError):
        service.autenticar(CONFIG, "11111111111")


def test_autenticar_cliente_nao_encontrado(monkeypatch):
    _mock_repo(monkeypatch, None)
    with pytest.raises(ClienteNaoEncontradoError):
        service.autenticar(CONFIG, CPF_VALIDO)


def test_autenticar_cliente_inativo(monkeypatch):
    _mock_repo(monkeypatch, Cliente(id=1, nome="X", status="INATIVO"))
    with pytest.raises(ClienteInativoError):
        service.autenticar(CONFIG, CPF_VALIDO)
