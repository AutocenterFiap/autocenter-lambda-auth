from auth_fn import cpf


class TestNormalizar:
    def test_remove_formatacao(self):
        assert cpf.normalizar("123.456.789-01") == "12345678901"

    def test_none_vira_string_vazia(self):
        assert cpf.normalizar(None) == ""


class TestCpfValido:
    def test_cpf_valido_sem_formatacao(self):
        # CPF de exemplo do seed (V2): João da Silva
        assert cpf.cpf_valido("12345678909") is True

    def test_cpf_valido_com_formatacao(self):
        assert cpf.cpf_valido("123.456.789-09") is True

    def test_cpf_com_digito_verificador_errado(self):
        assert cpf.cpf_valido("12345678901") is False

    def test_cpf_com_tamanho_invalido(self):
        assert cpf.cpf_valido("123456") is False

    def test_cpf_todos_digitos_iguais(self):
        assert cpf.cpf_valido("11111111111") is False

    def test_cpf_none(self):
        assert cpf.cpf_valido(None) is False

    def test_cpf_vazio(self):
        assert cpf.cpf_valido("") is False
