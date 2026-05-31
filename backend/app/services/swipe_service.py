"""Reglas de negocio de swipes."""

import logging

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.domain.recommendation.scoring import is_property_available
from app.infrastructure.repositories.match_repo import MatchRepository
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.infrastructure.repositories.swipe_repo import SwipeRepository
from app.schemas.swipe import SwipeRequest, SwipeResponse

logger = logging.getLogger(__name__)


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
        """Registra like/nope y crea match si corresponde.

        Regla importante de Fase 7:
        - El swipe/like es el evento principal del buyer.
        - El match formal requiere que la propiedad tenga owner_id.
        - Si el match formal falla por datos viejos/RLS/config, NO debemos perder
          el like; la pantalla de Matches del buyer puede listar desde swipes.
        """

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

        owner_id = str(row.get("owner_id") or "").strip()
        if owner_id and owner_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No puedes hacer swipe sobre una propiedad propia.",
            )

        # 1) Guardar SIEMPRE el swipe primero.
        # Si esto falla, sí debe fallar la request, porque entonces no se guardó
        # el like/nope real del usuario.
        self.swipe_repository.upsert_swipe(
            user_id=current_user.id,
            property_id=request.property_id,
            action=request.action,
        )

        created_match = False
        match_id: str | None = None
        message = "Interacción procesada correctamente."

        # 2) El match formal es una consecuencia del like.
        # Si una propiedad seed no tiene owner_id, igual queda guardado el like.
        if request.action == "like":
            if owner_id:
                try:
                    match_id = self.match_repository.upsert_match(
                        buyer_id=current_user.id,
                        owner_id=owner_id,
                        property_id=request.property_id,
                    )
                    created_match = True
                except Exception as exc:  # noqa: BLE001
                    logger.warning(
                        "No se pudo crear match formal para buyer=%s property=%s: %s",
                        current_user.id,
                        request.property_id,
                        exc,
                    )
                    message = (
                        "Like guardado. No se pudo crear el match formal; "
                        "revisa owner_id/SUPABASE_SECRET_KEY."
                    )
            else:
                message = (
                    "Like guardado. Esta propiedad todavía no tiene owner_id; "
                    "por eso no se creó match formal."
                )
        elif request.action == "nope":
            try:
                self.match_repository.delete_match(
                    buyer_id=current_user.id,
                    property_id=request.property_id,
                )
            except Exception as exc:  # noqa: BLE001
                logger.warning(
                    "No se pudo borrar match para buyer=%s property=%s: %s",
                    current_user.id,
                    request.property_id,
                    exc,
                )

        return SwipeResponse(
            message=message,
            property_id=request.property_id,
            action=request.action,
            is_match=created_match,
            created_match=created_match,
            match_id=match_id,
        )
