"""Endpoints de propiedades del propietario."""

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.common import SuccessResponse
from app.schemas.owner_property import (
    OwnerPropertyCreateRequest,
    OwnerPropertyListResponse,
    OwnerPropertyStatusRequest,
)
from app.schemas.property import PropertyDetailResponse
from app.services.owner_property_service import OwnerPropertyService

router = APIRouter()


@router.get("/owner/properties", response_model=OwnerPropertyListResponse)
async def listar_mis_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerPropertyListResponse:
    """Lista propiedades creadas por el owner."""

    return OwnerPropertyService().list_owner_properties(current_user, page, page_size)


@router.post(
    "/owner/properties",
    response_model=PropertyDetailResponse,
    status_code=status.HTTP_201_CREATED,
)
async def crear_propiedad_owner(
    request: OwnerPropertyCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Crea una propiedad publicada por el owner."""

    return OwnerPropertyService().create_property(current_user, request)


@router.patch(
    "/owner/properties/{property_id}/status",
    response_model=PropertyDetailResponse,
)
async def actualizar_estado_propiedad_owner(
    property_id: str,
    request: OwnerPropertyStatusRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Actualiza estado de una propiedad propia."""

    return OwnerPropertyService().update_status(current_user, property_id, request)


@router.delete("/owner/properties/{property_id}", response_model=SuccessResponse)
async def eliminar_propiedad_owner(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Oculta una propiedad propia."""

    return OwnerPropertyService().soft_delete(current_user, property_id)
