"""Endpoints de propiedades para buyer."""

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.property import PropertyDetailResponse, PropertyListResponse
from app.services.property_service import PropertyService

router = APIRouter()


@router.get("/properties", response_model=PropertyListResponse)
async def obtener_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyListResponse:
    """Obtiene propiedades no vistas del usuario autenticado."""

    return PropertyService().list_for_user(current_user, page, page_size)


@router.get("/properties/{property_id}", response_model=PropertyDetailResponse)
async def obtener_detalle_propiedad(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Obtiene detalle normalizado de una propiedad."""

    return PropertyService().get_detail(property_id)
