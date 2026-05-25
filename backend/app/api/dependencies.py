from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.infrastructure.supabase.client import get_supabase_client

security = HTTPBearer(auto_error=True)


@dataclass(frozen=True)
class CurrentUser:
    """Usuario autenticado obtenido desde Supabase Auth."""

    id: str
    email: str | None = None


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> CurrentUser:
    """Valida el Bearer token enviado por Flutter.

    Flutter debe enviar:
    Authorization: Bearer <access_token_de_supabase>
    """

    token = credentials.credentials
    supabase = get_supabase_client()

    try:
        response = supabase.auth.get_user(token)
        user = getattr(response, "user", None)

        if user is None:
            raise ValueError("Supabase no devolvió usuario.")

        return CurrentUser(
            id=str(user.id),
            email=getattr(user, "email", None),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o sesión expirada.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
