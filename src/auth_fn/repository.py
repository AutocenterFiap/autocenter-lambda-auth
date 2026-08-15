"""Acesso ao banco gerenciado (RDS MySQL) para consultar clientes.

Usa conexão em nível de módulo para reaproveitar entre invocações "quentes"
da Lambda (container reuse), reduzindo latência.
"""
from dataclasses import dataclass
from typing import Optional

import pymysql

from .config import Config

_conn: Optional["pymysql.connections.Connection"] = None


@dataclass(frozen=True)
class Cliente:
    id: int
    nome: str
    status: str


def _get_connection(config: Config) -> "pymysql.connections.Connection":
    global _conn
    if _conn is not None:
        try:
            _conn.ping(reconnect=True)
            return _conn
        except Exception:
            _conn = None

    _conn = pymysql.connect(
        host=config.db_host,
        port=config.db_port,
        db=config.db_name,
        user=config.db_user,
        password=config.db_password,
        connect_timeout=config.db_connect_timeout,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )
    return _conn


def buscar_por_documento(config: Config, documento: str) -> Optional[Cliente]:
    """Busca um cliente pelo documento (CPF em dígitos). Retorna None se não existir."""
    conn = _get_connection(config)
    with conn.cursor() as cursor:
        cursor.execute(
            "SELECT id, nome, status FROM clientes WHERE documento = %s",
            (documento,),
        )
        row = cursor.fetchone()

    if row is None:
        return None
    return Cliente(id=row["id"], nome=row["nome"], status=row["status"])
