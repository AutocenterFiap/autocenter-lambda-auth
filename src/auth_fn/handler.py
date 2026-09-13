"""Entrypoint da AWS Lambda (integração proxy com API Gateway REST).

Handler configurado na infra como: auth_fn.handler.handler
"""
import json
import logging

from .config import load_config
from .errors import AuthError, CpfInvalidoError
from .service import autenticar

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_config = None


def get_config():
    global _config

    if _config is None:
        _config = load_config()

    return _config


def _resposta(status_code: int, corpo: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(corpo, ensure_ascii=False),
    }


def _extrair_cpf(event: dict) -> str:
    body = event.get("body")
    if body is None:
        raise CpfInvalidoError("Corpo da requisição ausente.")
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            raise CpfInvalidoError("Corpo da requisição não é um JSON válido.")
    if not isinstance(body, dict):
        raise CpfInvalidoError("Corpo da requisição inválido.")
    return body.get("cpf") or ""


def handler(event, context):
    """Recebe {"cpf": "..."} e devolve um JWT ou um erro estruturado."""
    try:
        cpf = _extrair_cpf(event or {})
        resultado = autenticar(get_config(), cpf)
        return _resposta(200, resultado)
    except AuthError as e:
        logger.info("Falha de autenticação: %s (%s)", e.codigo, e.mensagem)
        return _resposta(e.status_code, {"erro": e.codigo, "mensagem": e.mensagem})
    except Exception:  # noqa: BLE001 — última barreira: nunca vazar stacktrace ao cliente
        logger.exception("Erro inesperado na autenticação")
        return _resposta(500, {"erro": "ERRO_INTERNO", "mensagem": "Erro interno ao autenticar."})
