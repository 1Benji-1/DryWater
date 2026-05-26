"""Reglas de negocio de perfil y roles."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.profile_repo import ProfileRepository
from app.schemas.profile import BecomeOwnerResponse, ProfileResponse, ProfileUpdateRequest


class ProfileService:
    """Servicio de perfil."""

    def __init__(self, repository: ProfileRepository | None = None):
        self.repository = repository or ProfileRepository()

    @staticmethod
    def to_response(profile: dict, email: str | None = None) -> ProfileResponse:
        """Convierte fila de Supabase a ProfileResponse."""

        return ProfileResponse(
            id=str(profile.get("id")),
            email=email or profile.get("email"),
            full_name=profile.get("full_name"),
            phone=profile.get("phone"),
            role=str(profile.get("role") or "buyer"),
        )

    def get_profile(self, current_user: CurrentUser) -> ProfileResponse:
        """Devuelve perfil del usuario autenticado."""

        profile = self.repository.get_profile(
            user_id=current_user.id,
            email=current_user.email,
        )
        return self.to_response(profile, current_user.email)

    def update_profile(
        self,
        current_user: CurrentUser,
        request: ProfileUpdateRequest,
    ) -> ProfileResponse:
        """Actualiza datos editables del perfil."""

        profile = self.repository.update_profile(
            user_id=current_user.id,
            full_name=request.full_name,
            phone=request.phone,
            email=current_user.email,
        )
        return self.to_response(profile, current_user.email)

    def become_owner(self, current_user: CurrentUser) -> BecomeOwnerResponse:
        """Convierte al usuario actual en propietario."""

        profile = self.repository.become_owner(
            user_id=current_user.id,
            email=current_user.email,
        )
        return BecomeOwnerResponse(
            message="Rol propietario activado correctamente.",
            profile=self.to_response(profile, current_user.email),
        )

    def ensure_owner(self, current_user: CurrentUser) -> None:
        """Bloquea endpoints owner si el usuario no tiene rol correcto."""

        if not self.repository.is_owner_or_admin(current_user.id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Necesitas activar el rol propietario.",
            )
