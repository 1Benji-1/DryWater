"""Reglas de negocio para propiedades públicas/recomendadas."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.property import PropertyDetailResponse, PropertyListResponse
from app.services.recommendation_service import RecommendationService


class PropertyService:
    """Servicio de propiedades."""

    def __init__(
        self,
        repository: PropertyRepository | None = None,
        recommendation_service: RecommendationService | None = None,
    ):
        self.repository = repository or PropertyRepository()
        self.recommendation_service = recommendation_service or RecommendationService(
            property_repository=self.repository,
        )

    def list_for_user(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> PropertyListResponse:
        """Alias compatible para obtener recomendaciones."""

        return self.list_recommendations(current_user, page, page_size)

    def list_recommendations(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> PropertyListResponse:
        """Obtiene propiedades recomendadas con scoring Fase 6."""

        return self.recommendation_service.get_recommendations(
            current_user=current_user,
            page=page,
            page_size=page_size,
        )

    def get_detail(self, property_id: str) -> PropertyDetailResponse:
        """Obtiene detalle normalizado de una propiedad."""

        row = self.repository.find_card_by_id(property_id)
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El inmueble no existe.",
            )
        return PropertyDetailResponse.from_supabase_row(row)
