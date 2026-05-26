"""Utilidades de paginación para respuestas API."""

from app.schemas.common import PaginationMeta


def build_pagination(page: int, page_size: int, total: int) -> PaginationMeta:
    """Construye metadatos de paginación consistentes."""

    return PaginationMeta(
        page=page,
        page_size=page_size,
        total=total,
        has_next=(page * page_size) < total,
    )
