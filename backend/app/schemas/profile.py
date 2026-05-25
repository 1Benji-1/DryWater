"""Schemas de perfil de usuario."""

from pydantic import BaseModel, Field


class ProfileResponse(BaseModel):
    """Perfil del usuario autenticado."""

    id: str
    email: str | None = None
    full_name: str | None = None
    phone: str | None = None
    role: str = Field(default="buyer")


class ProfileUpdateRequest(BaseModel):
    """Datos editables del perfil."""

    full_name: str | None = Field(default=None, max_length=120)
    phone: str | None = Field(default=None, max_length=30)


class BecomeOwnerResponse(BaseModel):
    """Respuesta al activar rol propietario."""

    status: str = Field(default="success")
    message: str
    profile: ProfileResponse
