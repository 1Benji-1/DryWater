"""Endpoints de amenidades."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.services.amenity_service import AmenityService

router = APIRouter()


@router.get("/amenities", response_model=list[str])
async def listar_amenities(
    current_user: CurrentUser = Depends(get_current_user),
) -> list[str]:
    """Lista amenities disponibles para formularios."""

    return AmenityService().list_amenities()
