import importlib
import sys
import types

import pytest


def _reload_config_module():
    module = importlib.import_module("auth_fn.config")
    return importlib.reload(module)


def test_load_config_usa_variaveis_de_ambiente_diretas_sem_boto3(monkeypatch):
    fake_boto3 = types.SimpleNamespace(
        client=lambda *args, **kwargs: pytest.fail("boto3 client should not be created")
    )
    monkeypatch.setitem(sys.modules, "boto3", fake_boto3)
    monkeypatch.delenv("LOCAL_AUTH", raising=False)
    monkeypatch.setenv("JWT_SECRET", "jwt-test-secret")
    monkeypatch.setenv("DB_PASSWORD", "db-test-secret")
    monkeypatch.setenv("JWT_ISSUER", "Issuer de teste")
    monkeypatch.setenv("JWT_EXP_MINUTES", "45")
    monkeypatch.setenv("DB_HOST", "db.example.internal")
    monkeypatch.setenv("DB_PORT", "3307")
    monkeypatch.setenv("DB_NAME", "autocenter")
    monkeypatch.setenv("DB_USER", "auth")
    monkeypatch.setenv("DB_CONNECT_TIMEOUT", "12")

    config_module = _reload_config_module()
    config = config_module.load_config()

    assert config.jwt_secret == "jwt-test-secret"
    assert config.db_password == "db-test-secret"
    assert config.jwt_issuer == "Issuer de teste"
    assert config.jwt_exp_minutes == 45
    assert config.db_host == "db.example.internal"
    assert config.db_port == 3307
    assert config.db_name == "autocenter"
    assert config.db_user == "auth"
    assert config.db_connect_timeout == 12


def test_load_config_preserva_defaults_locais_sem_boto3(monkeypatch):
    fake_boto3 = types.SimpleNamespace(
        client=lambda *args, **kwargs: pytest.fail("boto3 client should not be created")
    )
    monkeypatch.setitem(sys.modules, "boto3", fake_boto3)
    monkeypatch.setenv("LOCAL_AUTH", "true")
    monkeypatch.setenv("JWT_SECRET", "jwt-test-secret")
    monkeypatch.setenv("DB_PASSWORD", "db-test-secret")

    config_module = _reload_config_module()
    config = config_module.load_config()

    assert config.jwt_secret == "jwt-test-secret"
    assert config.db_password == "db-test-secret"
    assert config.jwt_issuer == "Auto Center Fiap"
    assert config.jwt_exp_minutes == 30
    assert config.db_host == "localhost"
    assert config.db_port == 3306
    assert config.db_name == "autocenterdb"
    assert config.db_user == "autocenter"
    assert config.db_connect_timeout == 5


def test_load_config_exige_variaveis_em_producao(monkeypatch):
    monkeypatch.delenv("LOCAL_AUTH", raising=False)
    for key in [
        "JWT_SECRET",
        "DB_PASSWORD",
        "JWT_ISSUER",
        "JWT_EXP_MINUTES",
        "DB_HOST",
        "DB_PORT",
        "DB_NAME",
        "DB_USER",
        "DB_CONNECT_TIMEOUT",
    ]:
        monkeypatch.delenv(key, raising=False)

    config_module = _reload_config_module()

    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        config_module.load_config()


def test_load_authorizer_config_nao_exige_dados_do_banco(monkeypatch):
    monkeypatch.delenv("LOCAL_AUTH", raising=False)
    monkeypatch.setenv("JWT_SECRET", "jwt-test-secret")
    monkeypatch.setenv("JWT_ISSUER", "Issuer de teste")
    monkeypatch.setenv("JWT_EXP_MINUTES", "15")

    config_module = _reload_config_module()
    config = config_module.load_authorizer_config()

    assert config.jwt_secret == "jwt-test-secret"
    assert config.jwt_issuer == "Issuer de teste"
    assert config.jwt_exp_minutes == 15
