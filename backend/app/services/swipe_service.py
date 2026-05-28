"""Reglas de negocio de swipes."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.domain.recommendation.scoring import is_property_available
from app.infrastructure.repositories.match_repo import MatchRepository
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.infrastructure.repositories.swipe_repo import SwipeRepository
from app.schemas.swipe import SwipeRequest, SwipeResponse


class SwipeService:
    """Servicio de swipes."""

    def __init__(
        self,
        property_repository: PropertyRepository | None = None,
        swipe_repository: SwipeRepository | None = None,
        match_repository: MatchRepository | None = None,
    ):
        self.property_repository = property_repository or PropertyRepository()
        self.swipe_repository = swipe_repository or SwipeRepository()
        self.match_repository = match_repository or MatchRepository()

    def record_swipe(
        self,
        current_user: CurrentUser,
        request: SwipeRequest,
    ) -> SwipeResponse:
        """Registra like/nope y crea match si corresponde."""

        row = self.property_repository.find_card_by_id(request.property_id)
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El inmueble no existe.",
            )

        if not is_property_available(row):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="La propiedad ya no está disponible.",
            )

        owner_id = str(row.get("owner_id") or "")
        if owner_id and owner_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes hacer swipe sobre una propiedad propia.",
            )

        self.swipe_repository.upsert_swipe(
            user_id=current_user.id,
            property_id=request.property_id,
            action=request.action,
        )

        created_match = False
        match_id: str | None = None

        if request.action == "like" and owner_id:
            match_id = self.match_repository.upsert_match(
                buyer_id=current_user.id,
                owner_id=owner_id,
                property_id=request.property_id,
            )
            created_match = True
        elif request.action == "nope":
            self.match_repository.delete_match(
                buyer_id=current_user.id,
                property_id=request.property_id,
            )

        return SwipeResponse(
            message="Interacción procesada correctamente.",
            property_id=request.property_id,
            action=request.action,
            is_match=created_match,
            created_match=created_match,
            match_id=match_id,
        )
