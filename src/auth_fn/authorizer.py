import jwt

from .config import load_authorizer_config

_config = None


def get_config():
    global _config

    if _config is None:
        _config = load_authorizer_config()

    return _config


def _get_bearer_token(event: dict) -> str:
    headers = event.get("headers")
    if not isinstance(headers, dict):
        raise ValueError("Missing headers")

    authorization = None
    for header_name, header_value in headers.items():
        if isinstance(header_name, str) and header_name.lower() == "authorization":
            authorization = header_value
            break

    if not isinstance(authorization, str):
        raise ValueError("Missing authorization header")

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise ValueError("Malformed bearer token")

    return token


def handler(event: dict, context: object) -> dict:
    try:
        token = _get_bearer_token(event or {})
        config = get_config()
        jwt.decode(
            token,
            config.jwt_secret,
            algorithms=["HS256"],
            issuer=config.jwt_issuer,
            options={"require": ["exp"]},
        )
        return {"isAuthorized": True}
    except (ValueError, jwt.InvalidTokenError):
        return {"isAuthorized": False}
