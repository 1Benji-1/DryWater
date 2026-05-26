"""Endpoints de perfil autenticado."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.profile import BecomeOwnerResponse, ProfileResponse, ProfileUpdateRequest
from app.services.profile_service import ProfileService

router = APIRouter()


@router.get("/me", response_model=ProfileResponse)
async def obtener_mi_perfil(
    current_user: CurrentUser = Depends(get_current_user),
) -> ProfileResponse:
    """Devuelve perfil del usuario autenticado."""

    return ProfileService().get_profile(current_user)


@router.patch("/me", response_model=ProfileResponse)
async def actualizar_mi_perfil(
    request: ProfileUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> ProfileResponse:
    """Actualiza nombre o teléfono del perfil."""

    return ProfileService().update_profile(current_user, request)


@router.post("/me/become-owner", response_model=BecomeOwnerResponse)
async def activar_rol_propietario(
    current_user: CurrentUser = Depends(get_current_user),
) -> BecomeOwnerResponse:
    """Convierte al usuario actual en propietario."""

    return ProfileService().become_owner(current_user)
