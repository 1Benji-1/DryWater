"""Reglas de negocio del panel de propietario."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.common import SuccessResponse
from app.schemas.owner_property import (
    OwnerPropertyCreateRequest,
    OwnerPropertyListResponse,
    OwnerPropertyStatusRequest,
)
from app.schemas.property import PropertyDetailResponse, PropertySummaryResponse
from app.services.profile_service import ProfileService
from app.utils.pagination import build_pagination


class OwnerPropertyService:
    """Servicio de propiedades de owner."""

    def __init__(
        self,
        property_repository: PropertyRepository | None = None,
        profile_service: ProfileService | None = None,
    ):
        self.property_repository = property_repository or PropertyRepository()
        self.profile_service = profile_service or ProfileService()

    def list_owner_properties(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> OwnerPropertyListResponse:
        """Lista propiedades creadas por el owner."""

        self.profile_service.ensure_owner(current_user)
        rows, total = self.property_repository.list_owner_cards(
            owner_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return OwnerPropertyListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def create_property(
        self,
        current_user: CurrentUser,
        request: OwnerPropertyCreateRequest,
    ) -> PropertyDetailResponse:
        """Crea una propiedad publicada por el owner."""

        row = self.property_repository.create_owner_property(
            owner_id=current_user.id,
            payload=request.model_dump(),
        )
        return PropertyDetailResponse.from_supabase_row(row)

    def update_status(
        self,
        current_user: CurrentUser,
        property_id: str,
        request: OwnerPropertyStatusRequest,
    ) -> PropertyDetailResponse:
        """Actualiza estado de una propiedad propia."""

        self.profile_service.ensure_owner(current_user)
        row = self.property_repository.update_owner_property_status(
            owner_id=current_user.id,
            property_id=property_id,
            new_status=request.status,
        )
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La propiedad no existe o no te pertenece.",
            )
        return PropertyDetailResponse.from_supabase_row(row)

    def soft_delete(self, current_user: CurrentUser, property_id: str) -> SuccessResponse:
        """Oculta una propiedad propia."""

        self.profile_service.ensure_owner(current_user)
        deleted = self.property_repository.soft_delete_owner_property(
            owner_id=current_user.id,
            property_id=property_id,
        )
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La propiedad no existe o no te pertenece.",
            )
        return SuccessResponse(message="Propiedad ocultada correctamente.")
