"""Validação de CPF (formato + dígitos verificadores).

Portado de ValidadorCpf.java do app principal.
"""
import re

_NON_DIGITS = re.compile(r"\D")


def normalizar(cpf: str) -> str:
    """Remove qualquer formatação, deixando apenas dígitos."""
    if cpf is None:
        return ""
    return _NON_DIGITS.sub("", cpf)


def cpf_valido(cpf: str) -> bool:
    """Retorna True se o CPF é válido (11 dígitos + dígitos verificadores corretos)."""
    doc = normalizar(cpf)

    if len(doc) != 11:
        return False

    # Rejeita sequências repetidas (000...0, 111...1, etc.)
    if doc == doc[0] * 11:
        return False

    # Primeiro dígito verificador
    soma = sum(int(doc[i]) * (10 - i) for i in range(9))
    resto = (soma * 10) % 11
    if resto in (10, 11):
        resto = 0
    if resto != int(doc[9]):
        return False

    # Segundo dígito verificador
    soma = sum(int(doc[i]) * (11 - i) for i in range(10))
    resto = (soma * 10) % 11
    if resto in (10, 11):
        resto = 0
    return resto == int(doc[10])
