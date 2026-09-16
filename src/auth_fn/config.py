"""Configuração lida de variáveis de ambiente."""
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


@dataclass(frozen=True)
class AuthorizerConfig:
    jwt_secret: str
    jwt_issuer: str
    jwt_exp_minutes: int


def _local_auth_enabled() -> bool:
    return os.environ.get("LOCAL_AUTH", "").lower() == "true"


def _read_env_value(env_name: str, default: str | None = None) -> str:
    value = os.environ.get(env_name)
    if _local_auth_enabled():
        value = value or default

    if not value:
        scope = "quando LOCAL_AUTH=true" if _local_auth_enabled() else "na produção"
        raise RuntimeError(f"{env_name} deve ser definido {scope}.")

    return value


def _read_int_env(env_name: str, default: int | None = None) -> int:
    value = _read_env_value(env_name, None if default is None else str(default))
    try:
        return int(value)
    except ValueError as exc:
        raise RuntimeError(f"{env_name} deve conter um inteiro válido.") from exc


def _load_jwt_config() -> AuthorizerConfig:
    return AuthorizerConfig(
        jwt_secret=_read_env_value("JWT_SECRET", "123456789"),
        jwt_issuer=_read_env_value("JWT_ISSUER", "Auto Center Fiap"),
        jwt_exp_minutes=_read_int_env("JWT_EXP_MINUTES", 30),
    )


def load_authorizer_config() -> AuthorizerConfig:
    return _load_jwt_config()


def load_config() -> Config:
    jwt_config = _load_jwt_config()
    return Config(
        jwt_secret=jwt_config.jwt_secret,
        jwt_issuer=jwt_config.jwt_issuer,
        jwt_exp_minutes=jwt_config.jwt_exp_minutes,
        db_host=_read_env_value("DB_HOST", "localhost"),
        db_port=_read_int_env("DB_PORT", 3306),
        db_name=_read_env_value("DB_NAME", "autocenterdb"),
        db_user=_read_env_value("DB_USER", "autocenter"),
        db_password=_read_env_value("DB_PASSWORD", "autocenter123"),
        db_connect_timeout=_read_int_env("DB_CONNECT_TIMEOUT", 5),
    )
