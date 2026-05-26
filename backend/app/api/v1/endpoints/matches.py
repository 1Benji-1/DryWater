"""Endpoints de matches."""

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.common import SuccessResponse
from app.schemas.match import MatchListResponse
from app.schemas.owner_property import MatchStatusUpdateRequest, OwnerMatchListResponse
from app.services.match_service import MatchService

router = APIRouter()


@router.get("/matches", response_model=MatchListResponse)
async def obtener_matches_usuario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> MatchListResponse:
    """Devuelve propiedades likeadas por el usuario autenticado."""

    return MatchService().list_buyer_matches(current_user, page, page_size)


@router.get("/owner/matches", response_model=OwnerMatchListResponse)
async def obtener_matches_propietario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerMatchListResponse:
    """Devuelve interesados en propiedades del propietario."""

    return MatchService().list_owner_matches(current_user, page, page_size)


@router.patch("/matches/{match_id}/status", response_model=SuccessResponse)
async def actualizar_estado_match(
    match_id: str,
    request: MatchStatusUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Actualiza estado active/contacted/archived."""

    return MatchService().update_status(current_user, match_id, request)
