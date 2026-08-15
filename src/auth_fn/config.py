"""Configuração lida de variáveis de ambiente.

Em produção, os valores sensíveis (JWT_SECRET, DB_PASSWORD) devem vir do
AWS Secrets Manager / SSM injetados como variáveis de ambiente pela infra (Terraform).
Os defaults abaixo servem apenas para desenvolvimento/local.
"""
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Config:
    # JWT — precisa casar com o app principal para o token ser aceito
    jwt_secret: str
    jwt_issuer: str
    jwt_exp_minutes: int

    # Banco de dados gerenciado (RDS MySQL)
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str
    db_connect_timeout: int


def load_config() -> Config:
    return Config(
        jwt_secret=os.environ.get("JWT_SECRET", "123456789"),
        jwt_issuer=os.environ.get("JWT_ISSUER", "Auto Center Fiap"),
        jwt_exp_minutes=int(os.environ.get("JWT_EXP_MINUTES", "30")),
        db_host=os.environ.get("DB_HOST", "localhost"),
        db_port=int(os.environ.get("DB_PORT", "3306")),
        db_name=os.environ.get("DB_NAME", "autocenterdb"),
        db_user=os.environ.get("DB_USER", "autocenter"),
        db_password=os.environ.get("DB_PASSWORD", "autocenter123"),
        db_connect_timeout=int(os.environ.get("DB_CONNECT_TIMEOUT", "5")),
    )
