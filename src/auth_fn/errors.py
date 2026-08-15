"""Erros de negócio mapeados para respostas HTTP."""


class AuthError(Exception):
    """Erro de autenticação com status HTTP e código de negócio associados."""

    def __init__(self, status_code: int, codigo: str, mensagem: str):
        super().__init__(mensagem)
        self.status_code = status_code
        self.codigo = codigo
        self.mensagem = mensagem


class CpfInvalidoError(AuthError):
    def __init__(self, mensagem: str = "CPF inválido."):
        super().__init__(400, "CPF_INVALIDO", mensagem)


class ClienteNaoEncontradoError(AuthError):
    def __init__(self, mensagem: str = "Cliente não encontrado."):
        super().__init__(404, "CLIENTE_NAO_ENCONTRADO", mensagem)


class ClienteInativoError(AuthError):
    def __init__(self, mensagem: str = "Cliente não está ativo."):
        super().__init__(403, "CLIENTE_INATIVO", mensagem)
