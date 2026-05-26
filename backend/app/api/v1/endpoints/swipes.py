"""Endpoints de swipes."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.swipe import SwipeRequest, SwipeResponse
from app.services.swipe_service import SwipeService

router = APIRouter()


@router.post("/swipes", response_model=SwipeResponse)
async def registrar_swipe(
    swipe: SwipeRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SwipeResponse:
    """Registra like/nope del usuario autenticado."""

    return SwipeService().record_swipe(current_user, swipe)
