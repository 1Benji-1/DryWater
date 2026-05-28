"""Servicio de recomendaciones reales para Fase 6."""

from __future__ import annotations

from typing import Any

from app.api.dependencies import CurrentUser
from app.domain.graphs.zone_graph import build_zone_graph
from app.domain.recommendation.scoring import (
    RecommendationContext,
    is_property_available,
    normalize_text,
    safe_float,
    score_property,
    to_string_set,
)
from app.infrastructure.repositories.preference_repo import PreferenceRepository
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.infrastructure.repositories.swipe_repo import SwipeRepository
from app.infrastructure.repositories.zone_repo import ZoneRepository
from app.schemas.property import PropertyListResponse, PropertySummaryResponse
from app.utils.pagination import build_pagination


class RecommendationService:
    """Calcula el feed de propiedades recomendadas."""

    def __init__(
        self,
        property_repository: PropertyRepository | None = None,
        preference_repository: PreferenceRepository | None = None,
        swipe_repository: SwipeRepository | None = None,
        zone_repository: ZoneRepository | None = None,
    ):
        self.property_repository = property_repository or PropertyRepository()
        self.preference_repository = preference_repository or PreferenceRepository()
        self.swipe_repository = swipe_repository or SwipeRepository()
        self.zone_repository = zone_repository or ZoneRepository()

    def get_recommendations(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> PropertyListResponse:
        """Devuelve recomendaciones con exclusiones y scoring."""

        preferences = self.preference_repository.get_user_preferences(current_user.id)
        if not preferences:
            return PropertyListResponse(
                items=[],
                pagination=build_pagination(page, page_size, 0),
            )

        liked_cards = self.property_repository.get_liked_cards(current_user.id)
        liked_zones = {
            str(card.get("zone")) for card in liked_cards if card.get("zone")
        }
        liked_property_types = {
            str(card.get("property_type"))
            for card in liked_cards
            if card.get("property_type")
        }

        context = self._build_context(
            user_id=current_user.id,
            preferences=preferences,
            liked_zones=liked_zones,
            liked_property_types=liked_property_types,
        )

        reference_zone = self.property_repository.get_last_liked_zone(current_user.id)
        if not reference_zone:
            reference_zone = context.preferred_zone

        zone_connections = self.zone_repository.list_zone_connections()
        zone_graph = build_zone_graph(zone_connections)
        zone_order = zone_graph.bfs_recorrido_cercania(reference_zone)

        swiped_ids = self.swipe_repository.list_swiped_property_ids(current_user.id)
        cards = self.property_repository.list_available_cards()

        scored_cards: list[dict[str, Any]] = []
        for card in cards:
            if not self._passes_hard_filters(card, current_user.id, swiped_ids, context):
                continue

            score = score_property(card, context, zone_order)
            enriched = dict(card)
            enriched["score"] = score.total
            enriched["score_breakdown"] = {
                "price": score.price_score,
                "zone": score.zone_score,
                "amenities": score.amenities_score,
                "behavior": score.behavior_score,
                "freshness": score.freshness_score,
            }
            scored_cards.append(enriched)

        scored_cards.sort(
            key=lambda card: (
                -safe_float(card.get("score")),
                safe_float(card.get("price")),
                str(card.get("created_at") or ""),
            )
        )

        total = len(scored_cards)
        start = (page - 1) * page_size
        end = start + page_size
        items = [
            PropertySummaryResponse.from_supabase_row(row)
            for row in scored_cards[start:end]
        ]

        return PropertyListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def _build_context(
        self,
        user_id: str,
        preferences: dict[str, Any],
        liked_zones: set[str],
        liked_property_types: set[str],
    ) -> RecommendationContext:
        """Convierte preferencias persistidas en contexto de scoring."""

        desired_amenities = to_string_set(
            preferences.get("desired_amenities")
            or preferences.get("amenities")
            or preferences.get("preferred_amenities")
        )

        return RecommendationContext(
            user_id=user_id,
            max_budget=safe_float(
                preferences.get("max_budget")
                or preferences.get("budget_max")
                or preferences.get("budget")
            ),
            operation_type=str(preferences.get("operation_type") or ""),
            preferred_zone=str(
                preferences.get("preferred_zone")
                or preferences.get("zone")
                or preferences.get("preferred_zone_name")
                or ""
            ),
            preferred_property_type=str(preferences.get("property_type") or ""),
            desired_amenities=desired_amenities,
            liked_zones=liked_zones,
            liked_property_types=liked_property_types,
        )

    def _passes_hard_filters(
        self,
        card: dict[str, Any],
        user_id: str,
        swiped_ids: set[str],
        context: RecommendationContext,
    ) -> bool:
        """Aplica filtros que NO son negociables para el feed."""

        property_id = str(card.get("id") or "")
        if not property_id or property_id in swiped_ids:
            return False

        if str(card.get("owner_id") or "") == user_id:
            return False

        if not is_property_available(card):
            return False

        if context.operation_type and normalize_text(card.get("operation_type")) != normalize_text(
            context.operation_type
        ):
            return False

        if context.preferred_property_type and normalize_text(
            card.get("property_type")
        ) != normalize_text(context.preferred_property_type):
            return False

        price = safe_float(card.get("price"))
        if context.max_budget > 0 and price > context.max_budget * 1.20:
            return False

        return True
