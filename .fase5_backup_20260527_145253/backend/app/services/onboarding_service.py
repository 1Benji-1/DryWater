"""Reglas de negocio de onboarding."""

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.preference_repo import PreferenceRepository
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.onboarding import OnboardingRequest, OnboardingResponse


class OnboardingService:
    """Servicio de preferencias iniciales."""

    def __init__(
        self,
        preference_repository: PreferenceRepository | None = None,
        property_repository: PropertyRepository | None = None,
    ):
        self.preference_repository = preference_repository or PreferenceRepository()
        self.property_repository = property_repository or PropertyRepository()

    def save_preferences(
        self,
        current_user: CurrentUser,
        request: OnboardingRequest,
    ) -> OnboardingResponse:
        """Guarda preferencias iniciales del usuario autenticado."""

        self.preference_repository.upsert_user_preferences(
            user_id=current_user.id,
            max_budget=request.budget,
            operation_type=request.operation_type,
            preferred_zone=request.preferred_zone,
        )
        available = self.property_repository.count_available_for_preferences(
            max_budget=request.budget,
            operation_type=request.operation_type,
        )
        return OnboardingResponse(
            message="Perfil inicial creado con éxito.",
            user_id=current_user.id,
            available_properties=available,
        )
