"""Regra de negócio da autenticação, independente do transporte (API Gateway).

Fluxo:
  1. valida o CPF (formato + dígitos verificadores)
  2. consulta o cliente no banco (existência)
  3. valida o status do cliente (precisa estar ATIVO)
  4. gera o JWT
"""
from . import cpf as cpf_util
from . import jwt_service
from .config import Config
from .errors import ClienteInativoError, ClienteNaoEncontradoError, CpfInvalidoError
from .repository import buscar_por_documento

STATUS_ATIVO = "ATIVO"


def autenticar(config: Config, cpf_bruto: str) -> dict:
    """Executa o fluxo de autenticação e devolve o payload de sucesso.

    Lança AuthError (CpfInvalido/ClienteNaoEncontrado/ClienteInativo) em falha.
    """
    if not cpf_util.cpf_valido(cpf_bruto):
        raise CpfInvalidoError()

    documento = cpf_util.normalizar(cpf_bruto)

    cliente = buscar_por_documento(config, documento)
    if cliente is None:
        raise ClienteNaoEncontradoError()

    if (cliente.status or "").upper() != STATUS_ATIVO:
        raise ClienteInativoError(f"Cliente com status '{cliente.status}' não pode autenticar.")

    token, expira_em = jwt_service.gerar_token(config, documento, cliente.id, cliente.nome)

    return {
        "token": token,
        "tokenType": "Bearer",
        "expiraEm": expira_em,
        "clienteId": cliente.id,
        "nome": cliente.nome,
    }
