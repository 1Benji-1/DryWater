"""Endpoints de onboarding."""

from fastapi import APIRouter, Depends, status

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.onboarding import OnboardingRequest, OnboardingResponse
from app.services.onboarding_service import OnboardingService

router = APIRouter()


@router.post(
    "/onboarding",
    response_model=OnboardingResponse,
    status_code=status.HTTP_201_CREATED,
)
async def iniciar_onboarding(
    request: OnboardingRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> OnboardingResponse:
    """Guarda preferencias iniciales del usuario autenticado."""

    return OnboardingService().save_preferences(current_user, request)
