"""Reglas de negocio para propiedades públicas/recomendadas."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.property import (
    PropertyDetailResponse,
    PropertyListResponse,
    PropertySummaryResponse,
)
from app.utils.pagination import build_pagination


class PropertyService:
    """Servicio de propiedades."""

    def __init__(self, repository: PropertyRepository | None = None):
        self.repository = repository or PropertyRepository()

    def list_for_user(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> PropertyListResponse:
        """Obtiene propiedades recomendadas/no vistas del usuario autenticado."""

        rows, total = self.repository.list_cards_for_user(
            user_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return PropertyListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def get_detail(self, property_id: str) -> PropertyDetailResponse:
        """Obtiene detalle normalizado de una propiedad."""

        row = self.repository.find_card_by_id(property_id)
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El inmueble no existe.",
            )
        return PropertyDetailResponse.from_supabase_row(row)
