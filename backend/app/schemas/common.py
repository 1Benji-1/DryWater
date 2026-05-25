"""Schemas compartidos para respuestas estándar de la API."""

from typing import Any

from pydantic import BaseModel, Field


class ApiError(BaseModel):
    """Objeto interno de error estándar."""

    code: str = Field(..., examples=["RESOURCE_NOT_FOUND"])
    message: str = Field(..., examples=["No se encontró el recurso solicitado."])
    details: dict[str, Any] | None = Field(default=None)


class ErrorResponse(BaseModel):
    """Respuesta estándar de error.

    Formato:
    {
      "error": {
        "code": "...",
        "message": "...",
        "details": {}
      }
    }
    """

    error: ApiError


class PaginationMeta(BaseModel):
    """Metadatos de paginación para listados."""

    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    total: int = Field(default=0, ge=0)
    has_next: bool = Field(default=False)


class SuccessResponse(BaseModel):
    """Respuesta simple de éxito."""

    status: str = Field(default="success")
    message: str
