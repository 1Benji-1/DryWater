"""Reglas de negocio de matches."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.match_repo import MatchRepository
from app.schemas.common import SuccessResponse
from app.schemas.match import MatchListResponse
from app.schemas.owner_property import (
    MatchStatusUpdateRequest,
    OwnerMatchListResponse,
    OwnerMatchResponse,
)
from app.schemas.property import PropertySummaryResponse
from app.services.profile_service import ProfileService
from app.utils.pagination import build_pagination


class MatchService:
    """Servicio de matches para buyer y owner."""

    def __init__(
        self,
        repository: MatchRepository | None = None,
        profile_service: ProfileService | None = None,
    ):
        self.repository = repository or MatchRepository()
        self.profile_service = profile_service or ProfileService()

    def list_buyer_matches(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> MatchListResponse:
        """Devuelve propiedades likeadas por el usuario autenticado."""

        rows, total = self.repository.list_match_cards(
            user_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return MatchListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def list_owner_matches(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> OwnerMatchListResponse:
        """Devuelve interesados en propiedades del propietario."""

        self.profile_service.ensure_owner(current_user)
        rows, total = self.repository.list_owner_matches(
            owner_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [
            OwnerMatchResponse(
                match_id=row["match_id"],
                status=row["status"],
                buyer_id=row["buyer_id"],
                buyer_name=row.get("buyer_name"),
                buyer_email=row.get("buyer_email"),
                property=PropertySummaryResponse.from_supabase_row(row["property"]),
            )
            for row in rows
        ]
        return OwnerMatchListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def update_status(
        self,
        current_user: CurrentUser,
        match_id: str,
        request: MatchStatusUpdateRequest,
    ) -> SuccessResponse:
        """Actualiza estado active/contacted/archived."""

        updated = self.repository.update_match_status(
            user_id=current_user.id,
            match_id=match_id,
            status=request.status,
        )
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El match no existe o no te pertenece.",
            )
        return SuccessResponse(message="Match actualizado correctamente.")
