"""Scoring modular para recomendaciones de propiedades.

Fase 6 separa el algoritmo del endpoint y del repositorio para que
el ranking pueda evolucionar sin romper la API.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any


AVAILABLE_STATUSES = {"available", "published"}
BLOCKED_STATUSES = {"draft", "paused", "hidden", "rented", "sold", "deleted"}


def normalize_text(value: object) -> str:
    """Normaliza texto para comparar filtros sin sensibilidad a mayúsculas."""

    return str(value or "").strip().lower()


def safe_float(value: object, default: float = 0.0) -> float:
    """Convierte números de Supabase/CSV a float sin romper el flujo."""

    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return default


def to_string_set(value: object) -> set[str]:
    """Convierte listas/strings de amenidades a un set normalizado."""

    if isinstance(value, list):
        return {normalize_text(item) for item in value if normalize_text(item)}

    if isinstance(value, str):
        separator = "|" if "|" in value else ","
        return {
            normalize_text(item)
            for item in value.split(separator)
            if normalize_text(item)
        }

    return set()


def is_property_available(card: dict[str, Any]) -> bool:
    """Valida que una propiedad pueda aparecer en el feed."""

    status = normalize_text(card.get("status"))
    is_active = card.get("is_active")

    if is_active is False:
        return False
    if status in BLOCKED_STATUSES:
        return False
    if status and status not in AVAILABLE_STATUSES:
        return False

    return True


@dataclass(frozen=True)
class RecommendationContext:
    """Preferencias y comportamiento necesarios para puntuar propiedades."""

    user_id: str
    max_budget: float
    operation_type: str
    preferred_zone: str = ""
    preferred_property_type: str = ""
    desired_amenities: set[str] = field(default_factory=set)
    liked_zones: set[str] = field(default_factory=set)
    liked_property_types: set[str] = field(default_factory=set)


@dataclass(frozen=True)
class ScoreBreakdown:
    """Detalle del score para depurar recomendaciones."""

    total: float
    price_score: float
    zone_score: float
    amenities_score: float
    behavior_score: float
    freshness_score: float


def calculate_price_score(price: float, max_budget: float) -> float:
    """Puntúa el precio según cercanía al presupuesto máximo."""

    if max_budget <= 0:
        return 0.0
    if price <= 0:
        return 0.0
    if price <= max_budget:
        return 1.0
    if price <= max_budget * 1.10:
        return 0.60
    if price <= max_budget * 1.20:
        return 0.30
    return 0.0


def calculate_zone_score(
    zone: str,
    preferred_zone: str,
    liked_zones: set[str],
    zone_order: list[str],
) -> float:
    """Puntúa cercanía de zona usando BFS/orden del grafo."""

    normalized_zone = normalize_text(zone)
    normalized_preferred = normalize_text(preferred_zone)
    normalized_liked = {normalize_text(item) for item in liked_zones}

    if normalized_zone and normalized_zone in normalized_liked:
        return 1.0
    if normalized_zone and normalized_zone == normalized_preferred:
        return 0.95

    normalized_order = [normalize_text(item) for item in zone_order]
    if normalized_zone in normalized_order:
        index = normalized_order.index(normalized_zone)
        return max(0.20, 0.85 - (index * 0.15))

    return 0.20


def calculate_amenities_score(
    card_amenities: object,
    desired_amenities: set[str],
) -> float:
    """Puntúa intersección de amenidades deseadas vs. propiedad."""

    if not desired_amenities:
        return 0.50

    property_amenities = to_string_set(card_amenities)
    if not property_amenities:
        return 0.0

    matches = property_amenities.intersection(desired_amenities)
    return len(matches) / len(desired_amenities)


def calculate_behavior_score(
    card: dict[str, Any],
    liked_zones: set[str],
    liked_property_types: set[str],
) -> float:
    """Puntúa comportamiento histórico simple del usuario."""

    points = 0.0
    checks = 0

    if liked_zones:
        checks += 1
        if normalize_text(card.get("zone")) in {normalize_text(z) for z in liked_zones}:
            points += 1.0

    if liked_property_types:
        checks += 1
        if normalize_text(card.get("property_type")) in {
            normalize_text(t) for t in liked_property_types
        }:
            points += 1.0

    if checks == 0:
        return 0.50

    return points / checks


def calculate_freshness_score(created_at: object) -> float:
    """Puntúa frescura de la publicación cuando existe created_at."""

    if not created_at:
        return 0.50

    try:
        raw = str(created_at).replace("Z", "+00:00")
        created = datetime.fromisoformat(raw)
        if created.tzinfo is None:
            created = created.replace(tzinfo=timezone.utc)
        age_days = (datetime.now(timezone.utc) - created).days
    except ValueError:
        return 0.50

    if age_days <= 7:
        return 1.0
    if age_days <= 30:
        return 0.75
    if age_days <= 90:
        return 0.50
    return 0.25


def score_property(
    card: dict[str, Any],
    context: RecommendationContext,
    zone_order: list[str],
) -> ScoreBreakdown:
    """Calcula score total ponderado para una propiedad."""

    price_score = calculate_price_score(
        price=safe_float(card.get("price")),
        max_budget=context.max_budget,
    )
    zone_score = calculate_zone_score(
        zone=str(card.get("zone") or ""),
        preferred_zone=context.preferred_zone,
        liked_zones=context.liked_zones,
        zone_order=zone_order,
    )
    amenities_score = calculate_amenities_score(
        card_amenities=card.get("amenities"),
        desired_amenities=context.desired_amenities,
    )
    behavior_score = calculate_behavior_score(
        card=card,
        liked_zones=context.liked_zones,
        liked_property_types=context.liked_property_types,
    )
    freshness_score = calculate_freshness_score(card.get("created_at"))

    total = (
        price_score * 0.25
        + zone_score * 0.25
        + amenities_score * 0.20
        + behavior_score * 0.20
        + freshness_score * 0.10
    )

    return ScoreBreakdown(
        total=round(total, 4),
        price_score=round(price_score, 4),
        zone_score=round(zone_score, 4),
        amenities_score=round(amenities_score, 4),
        behavior_score=round(behavior_score, 4),
        freshness_score=round(freshness_score, 4),
    )
