"""Invoca o handler localmente, sem Docker/SAM.

Útil para um teste de integração rápido contra um MySQL local (ex.: o do
docker-compose do app, após o app ter rodado as migrações Flyway).

Uso:
    python scripts/local_invoke.py 11144477735

As credenciais do banco vêm das variáveis de ambiente (ver auth_fn/config.py);
os defaults apontam para o MySQL local do docker-compose.
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from auth_fn.handler import handler  # noqa: E402


def main() -> None:
    cpf = sys.argv[1] if len(sys.argv) > 1 else "11144477735"
    event = {"body": json.dumps({"cpf": cpf})}
    resposta = handler(event, None)
    print(json.dumps(resposta, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
