#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RENT APP - FASE 6 ONLY
# Swipe y recomendaciones reales
# ------------------------------------------------------------
# Este script NO hace git, NO instala dependencias, NO ejecuta
# flutter pub get, NO ejecuta pip install y NO hace deploy.
#
# Enfoque Fase 6:
# - RecommendationService separado.
# - Scoring desacoplado en domain/recommendation/scoring.py.
# - Exclusión de propiedades vistas, propias e inactivas/pausadas.
# - Grafo de zonas cargado desde DB con fallback al grafo actual.
# - Endpoint GET /api/v1/properties/recommendations.
# - POST /api/v1/swipes devuelve resultado útil de match.
# - Flutter consume recommendations y tipa la respuesta de swipe.
# ============================================================

ROOT_DIR="$(pwd)"
BACKUP_DIR="${ROOT_DIR}/.fase6_backup_$(date +%Y%m%d_%H%M%S)"

info() {
  printf '\033[1;34m[FASE 6]\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33m[AVISO]\033[0m %s\n' "$1"
}

fail() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
  exit 1
}

backup_file() {
  local file_path="$1"
  if [[ -f "$file_path" ]]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$file_path")"
    cp "$file_path" "${BACKUP_DIR}/${file_path}"
  fi
}

write_file() {
  local file_path="$1"
  backup_file "$file_path"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
}

require_project_root() {
  [[ -d "backend" ]] || fail "No encuentro backend/. Ejecuta este .sh desde la raíz del proyecto."
  [[ -d "frontend" ]] || fail "No encuentro frontend/. Ejecuta este .sh desde la raíz del proyecto."
  [[ -d "backend/app" ]] || fail "No encuentro backend/app/."
  [[ -d "frontend/lib" ]] || fail "No encuentro frontend/lib/."
}

require_project_root

info "Aplicando SOLO Fase 6: swipe y recomendaciones reales..."
info "Backup de archivos modificados: ${BACKUP_DIR}"

# ============================================================
# BACKEND - Dominio de recomendaciones
# ============================================================

write_file "backend/app/domain/recommendation/__init__.py" <<'PY'
"""Dominio puro de recomendaciones.

Aquí viven algoritmos sin dependencia de FastAPI, Supabase ni Flutter.
"""
PY

write_file "backend/app/domain/recommendation/scoring.py" <<'PY'
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
PY

write_file "backend/app/domain/graphs/zone_graph.py" <<'PY'
"""Grafo de zonas cargable desde base de datos.

Fase 6 evita depender únicamente de zonas hardcodeadas. Si Supabase todavía
no tiene `zones` y `zone_connections`, se usa el grafo anterior como fallback.
"""

from __future__ import annotations

from collections import defaultdict, deque
from typing import Any

from app.domain.graphs.city_graph import grafo_scz


class ZoneGraph:
    """Grafo no dirigido para calcular cercanía por BFS."""

    def __init__(self, adjacency: dict[str, list[str]] | None = None):
        self.adjacency = adjacency or {}

    @classmethod
    def from_connection_rows(cls, rows: list[dict[str, Any]]) -> "ZoneGraph":
        """Construye grafo desde filas de Supabase.

        Soporta varias formas porque el esquema puede venir como IDs, nombres
        directos o relaciones embebidas de Supabase.
        """

        adjacency: dict[str, set[str]] = defaultdict(set)

        for row in rows:
            from_zone = cls._extract_zone_name(row, "from")
            to_zone = cls._extract_zone_name(row, "to")

            if not from_zone or not to_zone:
                continue

            adjacency[from_zone].add(to_zone)
            adjacency[to_zone].add(from_zone)

        return cls({key: sorted(value) for key, value in adjacency.items()})

    @staticmethod
    def _extract_zone_name(row: dict[str, Any], prefix: str) -> str:
        """Extrae nombre de zona desde distintas variantes de columnas."""

        direct_keys = (
            f"{prefix}_zone",
            f"{prefix}_zone_name",
            f"{prefix}_zone_label",
            f"{prefix}_zone_id",
        )
        for key in direct_keys:
            value = row.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

        nested = row.get(f"{prefix}_zone")
        if isinstance(nested, dict):
            for key in ("name", "label", "zone"):
                value = nested.get(key)
                if isinstance(value, str) and value.strip():
                    return value.strip()

        return ""

    def bfs_recorrido_cercania(self, start_zone: str) -> list[str]:
        """Devuelve zonas por cercanía usando cola FIFO."""

        if not start_zone:
            return []

        if start_zone not in self.adjacency:
            fallback = grafo_scz.bfs_recorrido_cercania(start_zone)
            return fallback if fallback else [start_zone]

        result: list[str] = []
        visited = {start_zone}
        queue: deque[str] = deque([start_zone])

        while queue:
            current = queue.popleft()
            result.append(current)

            for neighbor in self.adjacency.get(current, []):
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append(neighbor)

        return result


def build_zone_graph(rows: list[dict[str, Any]]) -> ZoneGraph:
    """Crea grafo desde DB o fallback al grafo actual."""

    graph = ZoneGraph.from_connection_rows(rows)
    if graph.adjacency:
        return graph

    return ZoneGraph(adjacency=grafo_scz.adyacencias)
PY

# ============================================================
# BACKEND - Repositorios base para Fase 6
# ============================================================

write_file "backend/app/infrastructure/repositories/zone_repo.py" <<'PY'
"""Repositorio de zonas y conexiones para recomendaciones."""

from app.infrastructure.supabase.client import get_supabase_client


class ZoneRepository:
    """Acceso a `zones` y `zone_connections`.

    Si las tablas todavía no existen, devuelve lista vacía para que el
    servicio use el fallback de `city_graph.py`.
    """

    def __init__(self):
        self.client = get_supabase_client()

    def list_zone_connections(self) -> list[dict]:
        """Lista conexiones entre zonas de Supabase si están disponibles."""

        queries = (
            "from_zone:zones!zone_connections_from_zone_id_fkey(name),"
            "to_zone:zones!zone_connections_to_zone_id_fkey(name),"
            "distance_score",
            "from_zone_name,to_zone_name,distance_score",
            "from_zone,to_zone,distance_score",
            "from_zone_id,to_zone_id,distance_score",
        )

        for select_query in queries:
            try:
                response = (
                    self.client.table("zone_connections")
                    .select(select_query)
                    .execute()
                )
                rows = response.data or []
                if rows:
                    return rows
            except Exception:
                continue

        return []
PY

write_file "backend/app/infrastructure/repositories/property_repo.py" <<'PY'
"""Repositorio de propiedades.

Fase 6: el repositorio queda enfocado en acceso a datos. El ranking vive en
RecommendationService + domain/recommendation/scoring.py.
"""

from app.domain.graphs.city_graph import grafo_scz
from app.infrastructure.repositories.amenity_repo import AmenityRepository
from app.infrastructure.repositories.preference_repo import PreferenceRepository
from app.infrastructure.repositories.profile_repo import ProfileRepository
from app.infrastructure.repositories.property_image_repo import PropertyImageRepository
from app.infrastructure.repositories.swipe_repo import SwipeRepository
from app.infrastructure.supabase.client import get_supabase_client


ACTIVE_STATUSES = {"available", "published"}
INACTIVE_STATUSES = {"draft", "paused", "hidden", "rented", "sold", "deleted"}


class PropertyRepository:
    """Acceso a propiedades y consultas de tarjetas."""

    def __init__(self):
        self.client = get_supabase_client()
        self.preferences = PreferenceRepository()
        self.swipes = SwipeRepository()
        self.profiles = ProfileRepository()
        self.amenities = AmenityRepository()
        self.images = PropertyImageRepository()

    def list_available_cards(self) -> list[dict]:
        """Lista propiedades publicables desde la view normalizada."""

        try:
            response = (
                self.client.table("property_cards")
                .select("*")
                .in_("status", list(ACTIVE_STATUSES))
                .execute()
            )
            return response.data or []
        except Exception:
            response = self.client.table("property_cards").select("*").execute()
            cards = response.data or []
            return [card for card in cards if self._is_available_row(card)]

    def _is_available_row(self, card: dict) -> bool:
        """Filtro Python defensivo para estados activos."""

        status = str(card.get("status") or "").strip().lower()
        is_active = card.get("is_active")

        if is_active is False:
            return False
        if status in INACTIVE_STATUSES:
            return False
        if status and status not in ACTIVE_STATUSES:
            return False
        return True

    def find_card_by_id(self, property_id: str) -> dict | None:
        """Busca una propiedad por UUID."""

        response = (
            self.client.table("property_cards")
            .select("*")
            .eq("id", property_id)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        return rows[0] if rows else None

    def get_liked_cards(self, user_id: str) -> list[dict]:
        """Devuelve tarjetas que el usuario marcó como like."""

        liked_ids = self.swipes.list_liked_property_ids(user_id)
        if not liked_ids:
            return []

        response = (
            self.client.table("property_cards")
            .select("*")
            .in_("id", list(liked_ids))
            .execute()
        )
        return response.data or []

    def get_last_liked_zone(self, user_id: str) -> str | None:
        """Obtiene la última zona likeada para priorizar el mazo."""

        property_id = self.swipes.get_last_liked_property_id(user_id)
        if not property_id:
            return None

        card = self.find_card_by_id(property_id)
        if not card:
            return None
        return card.get("zone")

    def list_cards_for_user(
        self,
        user_id: str,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        """Compatibilidad legacy: lista propiedades simples por preferencias.

        La ruta nueva de Fase 6 usa RecommendationService. Este método queda
        como fallback si algún import antiguo sigue llamándolo.
        """

        preferences = self.preferences.get_user_preferences(user_id)
        if not preferences:
            return [], 0

        max_budget = float(preferences.get("max_budget") or 0)
        operation_type = str(preferences.get("operation_type") or "")
        preferred_zone = str(preferences.get("preferred_zone") or "")

        swiped_ids = self.swipes.list_swiped_property_ids(user_id)
        cards = self.list_available_cards()

        candidates = []
        for card in cards:
            if str(card.get("id")) in swiped_ids:
                continue
            if str(card.get("owner_id") or "") == user_id:
                continue
            if str(card.get("operation_type", "")).lower() != operation_type.lower():
                continue
            if max_budget > 0 and float(card.get("price") or 0) > max_budget:
                continue
            candidates.append(card)

        last_liked_zone = self.get_last_liked_zone(user_id)
        reference_zone = last_liked_zone or preferred_zone
        zone_priority = grafo_scz.bfs_recorrido_cercania(reference_zone)

        def sort_key(card: dict) -> tuple[int, float]:
            zone = str(card.get("zone") or "")
            zone_index = zone_priority.index(zone) if zone in zone_priority else 999
            price = float(card.get("price") or 0)
            return zone_index, price

        candidates.sort(key=sort_key)
        total = len(candidates)
        start = (page - 1) * page_size
        end = start + page_size
        return candidates[start:end], total

    def count_available_for_preferences(self, max_budget: float, operation_type: str) -> int:
        """Cuenta propiedades disponibles para el onboarding."""

        cards = self.list_available_cards()
        return sum(
            1
            for card in cards
            if str(card.get("operation_type", "")).lower() == operation_type.lower()
            and float(card.get("price") or 0) <= max_budget
        )

    def create_owner_property(self, owner_id: str, payload: dict) -> dict:
        """Crea un inmueble publicado por el owner."""

        self.profiles.become_owner(owner_id)
        response = (
            self.client.table("properties")
            .insert(
                {
                    "owner_id": owner_id,
                    "title": payload["title"],
                    "description": payload.get("description") or "",
                    "price": payload["price"],
                    "currency": "BOB",
                    "operation_type": payload["operation_type"],
                    "property_type": payload["property_type"],
                    "zone": payload["zone"],
                    "status": "available",
                }
            )
            .execute()
        )

        created = (response.data or [])[0]
        property_id = str(created["id"])
        self.amenities.replace_property_amenities(
            property_id=property_id,
            amenity_names=payload.get("amenities") or [],
        )
        self.images.insert_property_images(
            property_id=property_id,
            images=payload.get("images") or [],
        )
        card = self.find_card_by_id(property_id)
        return card or created

    def list_owner_cards(
        self,
        owner_id: str,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        """Lista inmuebles publicados por el propietario."""

        response = (
            self.client.table("property_cards")
            .select("*")
            .eq("owner_id", owner_id)
            .order("created_at", desc=True)
            .execute()
        )
        cards = response.data or []
        total = len(cards)
        start = (page - 1) * page_size
        end = start + page_size
        return cards[start:end], total

    def update_owner_property_status(
        self,
        owner_id: str,
        property_id: str,
        new_status: str,
    ) -> dict | None:
        """Actualiza estado de una propiedad del owner."""

        existing = (
            self.client.table("properties")
            .select("id,owner_id")
            .eq("id", property_id)
            .eq("owner_id", owner_id)
            .limit(1)
            .execute()
        )
        if not existing.data:
            return None

        self.client.table("properties").update({"status": new_status}).eq(
            "id", property_id
        ).execute()
        return self.find_card_by_id(property_id)

    def soft_delete_owner_property(self, owner_id: str, property_id: str) -> bool:
        """Oculta una propiedad sin eliminar datos históricos."""

        card = self.update_owner_property_status(
            owner_id=owner_id,
            property_id=property_id,
            new_status="hidden",
        )
        return card is not None


# Alias temporal para compatibilidad si algún import antiguo quedara vivo.
repo_inmuebles = PropertyRepository()
PY

write_file "backend/app/infrastructure/repositories/swipe_repo.py" <<'PY'
"""Repositorio de swipes."""

from app.infrastructure.supabase.client import get_supabase_client


class SwipeRepository:
    """Acceso a swipes."""

    def __init__(self):
        self.client = get_supabase_client()

    def list_swiped_property_ids(self, user_id: str) -> set[str]:
        """Devuelve IDs de propiedades ya vistas por el usuario."""

        response = (
            self.client.table("swipes")
            .select("property_id")
            .eq("user_id", user_id)
            .execute()
        )
        return {str(row["property_id"]) for row in (response.data or [])}

    def list_liked_property_ids(self, user_id: str) -> set[str]:
        """Devuelve IDs de propiedades con like."""

        response = (
            self.client.table("swipes")
            .select("property_id")
            .eq("user_id", user_id)
            .eq("action", "like")
            .execute()
        )
        return {str(row["property_id"]) for row in (response.data or [])}

    def get_last_liked_property_id(self, user_id: str) -> str | None:
        """Obtiene el último inmueble likeado por el usuario."""

        response = (
            self.client.table("swipes")
            .select("property_id")
            .eq("user_id", user_id)
            .eq("action", "like")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        return str(rows[0].get("property_id")) if rows else None

    def upsert_swipe(self, user_id: str, property_id: str, action: str) -> None:
        """Registra o actualiza un swipe."""

        self.client.table("swipes").upsert(
            {
                "user_id": user_id,
                "property_id": property_id,
                "action": action,
            },
            on_conflict="user_id,property_id",
        ).execute()
PY

write_file "backend/app/infrastructure/repositories/match_repo.py" <<'PY'
"""Repositorio de matches."""

from app.infrastructure.supabase.client import get_supabase_client


class MatchRepository:
    """Acceso a matches y consultas relacionadas."""

    def __init__(self):
        self.client = get_supabase_client()

    def upsert_match(self, buyer_id: str, owner_id: str, property_id: str) -> str | None:
        """Crea o mantiene activo un match y devuelve su ID si Supabase lo retorna."""

        payload = {
            "buyer_id": buyer_id,
            "owner_id": owner_id,
            "property_id": property_id,
            "status": "active",
        }

        try:
            response = (
                self.client.table("matches")
                .upsert(payload, on_conflict="buyer_id,property_id")
                .execute()
            )
        except Exception:
            # Compatibilidad con esquemas que usen user_id en vez de buyer_id.
            fallback_payload = {
                "user_id": buyer_id,
                "owner_id": owner_id,
                "property_id": property_id,
                "status": "active",
            }
            response = (
                self.client.table("matches")
                .upsert(fallback_payload, on_conflict="user_id,property_id")
                .execute()
            )

        rows = response.data or []
        return str(rows[0].get("id")) if rows and rows[0].get("id") else None

    def delete_match(self, buyer_id: str, property_id: str) -> None:
        """Elimina match cuando el swipe cambia a nope."""

        try:
            self.client.table("matches").delete().eq("buyer_id", buyer_id).eq(
                "property_id", property_id
            ).execute()
        except Exception:
            self.client.table("matches").delete().eq("user_id", buyer_id).eq(
                "property_id", property_id
            ).execute()

    def list_match_cards(
        self,
        user_id: str,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        """Devuelve propiedades likeadas/matcheadas por el usuario."""

        response = (
            self.client.table("swipes")
            .select("property_id")
            .eq("user_id", user_id)
            .eq("action", "like")
            .order("created_at", desc=True)
            .execute()
        )
        ids = [str(row["property_id"]) for row in (response.data or [])]
        if not ids:
            return [], 0

        cards_response = (
            self.client.table("property_cards")
            .select("*")
            .in_("id", ids)
            .execute()
        )
        cards = cards_response.data or []

        order = {property_id: index for index, property_id in enumerate(ids)}
        cards.sort(key=lambda card: order.get(str(card.get("id")), 999))

        total = len(cards)
        start = (page - 1) * page_size
        end = start + page_size
        return cards[start:end], total

    def list_owner_matches(
        self,
        owner_id: str,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        """Lista interesados/matches de propiedades del propietario."""

        response = (
            self.client.table("matches")
            .select("*")
            .eq("owner_id", owner_id)
            .order("created_at", desc=True)
            .execute()
        )
        matches = response.data or []
        property_ids = [str(row["property_id"]) for row in matches]
        buyer_ids = [str(row.get("buyer_id") or row.get("user_id")) for row in matches]

        cards_by_id = {}
        if property_ids:
            cards_response = (
                self.client.table("property_cards")
                .select("*")
                .in_("id", property_ids)
                .execute()
            )
            cards_by_id = {
                str(card["id"]): card for card in (cards_response.data or [])
            }

        buyers_by_id = {}
        clean_buyer_ids = [buyer_id for buyer_id in buyer_ids if buyer_id]
        if clean_buyer_ids:
            buyers_response = (
                self.client.table("profiles")
                .select("*")
                .in_("id", clean_buyer_ids)
                .execute()
            )
            buyers_by_id = {
                str(buyer["id"]): buyer for buyer in (buyers_response.data or [])
            }

        enriched = []
        for match in matches:
            property_id = str(match.get("property_id"))
            buyer_id = str(match.get("buyer_id") or match.get("user_id"))
            card = cards_by_id.get(property_id)
            buyer = buyers_by_id.get(buyer_id, {})
            if not card:
                continue

            enriched.append(
                {
                    "match_id": str(match.get("id")),
                    "status": str(match.get("status") or "active"),
                    "buyer_id": buyer_id,
                    "buyer_name": buyer.get("full_name"),
                    "buyer_email": None,
                    "property": card,
                }
            )

        total = len(enriched)
        start = (page - 1) * page_size
        end = start + page_size
        return enriched[start:end], total

    def update_match_status(self, user_id: str, match_id: str, status: str) -> bool:
        """Actualiza estado de un match si pertenece al buyer u owner."""

        response = (
            self.client.table("matches")
            .select("*")
            .eq("id", match_id)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        if not rows:
            return False

        match = rows[0]
        buyer_id = str(match.get("buyer_id") or match.get("user_id"))
        if user_id not in {buyer_id, str(match.get("owner_id"))}:
            return False

        self.client.table("matches").update({"status": status}).eq(
            "id", match_id
        ).execute()
        return True
PY

# ============================================================
# BACKEND - Schemas y services Fase 6
# ============================================================

write_file "backend/app/schemas/swipe.py" <<'PY'
from typing import Literal

from pydantic import BaseModel, Field


class SwipeRequest(BaseModel):
    """Acción del usuario autenticado sobre una propiedad."""

    property_id: str = Field(
        ...,
        examples=["b8ebc4f0-1234-1234-1234-123456789000"],
    )
    action: Literal["like", "nope"] = Field(..., examples=["like"])


class SwipeResponse(BaseModel):
    """Resultado de procesar un swipe real."""

    status: str = Field(default="success")
    message: str
    property_id: str
    action: Literal["like", "nope"]
    is_match: bool = Field(default=False)
    created_match: bool = Field(default=False)
    match_id: str | None = Field(default=None)
PY

# property.py se actualiza solo para exponer score opcional sin romper contrato.
write_file "backend/app/schemas/property.py" <<'PY'
"""Schemas de propiedades/inmuebles."""

from pydantic import BaseModel, Field

from app.schemas.common import PaginationMeta


PLACEHOLDER_IMAGE_URL = "https://via.placeholder.com/800x600.png?text=Rent+App"


def _to_float(value: object, default: float = 0.0) -> float:
    """Convierte un valor numérico a float sin romper la API."""

    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return default


def _to_string_list(value: object) -> list[str]:
    """Convierte arrays de Supabase o strings heredados a lista limpia."""

    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]

    if isinstance(value, str):
        if "|" in value:
            return [item.strip() for item in value.split("|") if item.strip()]
        if "," in value:
            return [item.strip() for item in value.split(",") if item.strip()]
        if value.strip():
            return [value.strip()]

    return []


class PropertySummaryResponse(BaseModel):
    """Propiedad resumida para tarjetas y listados."""

    id: str = Field(..., examples=["b8ebc4f0-1234-1234-1234-123456789000"])
    title: str = Field(..., examples=["Departamento en Equipetrol"])
    description: str = Field(..., examples=["Piscina, Gimnasio, Amoblado"])
    price: float = Field(..., ge=0, examples=[3500])
    currency: str = Field(default="BOB", examples=["BOB"])
    operation_type: str = Field(..., examples=["Alquiler"])
    property_type: str = Field(..., examples=["Departamento"])
    zone: str = Field(..., examples=["Equipetrol"])
    image_url: str = Field(..., examples=[PLACEHOLDER_IMAGE_URL])
    amenities: list[str] = Field(default_factory=list)
    score: float | None = Field(default=None, ge=0, le=1)

    @classmethod
    def from_supabase_row(cls, row: dict) -> "PropertySummaryResponse":
        """Crea una respuesta limpia desde la view `property_cards`."""

        property_type = str(row.get("property_type") or "Inmueble")
        zone = str(row.get("zone") or "Sin zona")
        amenities = _to_string_list(row.get("amenities"))
        image_url = str(row.get("image_url") or PLACEHOLDER_IMAGE_URL)
        score = row.get("score")

        return cls(
            id=str(row.get("id")),
            title=str(row.get("title") or f"{property_type} en {zone}"),
            description=str(
                row.get("description")
                or (", ".join(amenities) if amenities else "Sin descripción")
            ),
            price=_to_float(row.get("price")),
            currency=str(row.get("currency") or "BOB"),
            operation_type=str(row.get("operation_type") or "Alquiler"),
            property_type=property_type,
            zone=zone,
            image_url=image_url,
            amenities=amenities,
            score=_to_float(score) if score is not None else None,
        )


class PropertyDetailResponse(PropertySummaryResponse):
    """Propiedad detallada para pantalla de detalle."""

    owner_id: str | None = Field(default=None)
    owner_name: str | None = Field(default=None)
    owner_phone: str | None = Field(default=None)
    status: str | None = Field(default=None)
    images: list[str] = Field(default_factory=list)

    @classmethod
    def from_supabase_row(cls, row: dict) -> "PropertyDetailResponse":
        """Crea una respuesta detallada desde la view `property_cards`."""

        summary = PropertySummaryResponse.from_supabase_row(row)
        images = _to_string_list(row.get("images"))

        return cls(
            **summary.model_dump(),
            owner_id=row.get("owner_id"),
            owner_name=row.get("owner_name"),
            owner_phone=row.get("owner_phone"),
            status=row.get("status"),
            images=images or [summary.image_url],
        )


class PropertyListResponse(BaseModel):
    """Respuesta paginada para propiedades."""

    items: list[PropertySummaryResponse]
    pagination: PaginationMeta
PY

write_file "backend/app/services/recommendation_service.py" <<'PY'
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
PY

write_file "backend/app/services/property_service.py" <<'PY'
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
PY

write_file "backend/app/services/swipe_service.py" <<'PY'
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
PY

write_file "backend/app/api/v1/endpoints/properties.py" <<'PY'
"""Endpoints de propiedades para buyer."""

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.property import PropertyDetailResponse, PropertyListResponse
from app.services.property_service import PropertyService

router = APIRouter()


@router.get("/properties/recommendations", response_model=PropertyListResponse)
async def obtener_recomendaciones(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyListResponse:
    """Obtiene recomendaciones reales con exclusiones y scoring."""

    return PropertyService().list_recommendations(current_user, page, page_size)


@router.get("/properties", response_model=PropertyListResponse)
async def obtener_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyListResponse:
    """Alias compatible: devuelve el mismo feed recomendado."""

    return PropertyService().list_for_user(current_user, page, page_size)


@router.get("/properties/{property_id}", response_model=PropertyDetailResponse)
async def obtener_detalle_propiedad(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Obtiene detalle normalizado de una propiedad."""

    return PropertyService().get_detail(property_id)
PY

# ============================================================
# FRONTEND - Fase 6: endpoint de recommendations y SwipeResult
# ============================================================

write_file "frontend/lib/features/swipes/domain/entities/swipe_result.dart" <<'DART'
class SwipeResult {
  final String status;
  final String message;
  final String propertyId;
  final String action;
  final bool isMatch;
  final bool createdMatch;
  final String? matchId;

  const SwipeResult({
    required this.status,
    required this.message,
    required this.propertyId,
    required this.action,
    required this.isMatch,
    required this.createdMatch,
    this.matchId,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      status: json['status']?.toString() ?? 'success',
      message: json['message']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      isMatch: json['is_match'] == true,
      createdMatch: json['created_match'] == true || json['is_match'] == true,
      matchId: json['match_id']?.toString(),
    );
  }

  bool get processed => status == 'success';
}
DART

write_file "frontend/lib/features/swipes/domain/repositories/swipe_repository.dart" <<'DART'
import '../entities/swipe_result.dart';

abstract class SwipeRepository {
  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  });
}
DART

write_file "frontend/lib/features/swipes/domain/usecases/send_swipe_usecase.dart" <<'DART'
import '../entities/swipe_result.dart';
import '../repositories/swipe_repository.dart';

class SendSwipeUseCase {
  final SwipeRepository _repository;

  const SendSwipeUseCase(this._repository);

  Future<SwipeResult> call({
    required String propertyId,
    required String action,
  }) {
    return _repository.sendSwipe(propertyId: propertyId, action: action);
  }
}
DART

write_file "frontend/lib/features/swipes/data/datasources/swipe_remote_datasource.dart" <<'DART'
import '../../../../services/api_service.dart';
import '../../domain/entities/swipe_result.dart';

class SwipeRemoteDataSource {
  final ApiService _apiService;

  SwipeRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  }) {
    return _apiService.sendSwipeAction(propertyId, action);
  }
}
DART

write_file "frontend/lib/features/swipes/data/repositories/swipe_repository_impl.dart" <<'DART'
import '../../domain/entities/swipe_result.dart';
import '../../domain/repositories/swipe_repository.dart';
import '../datasources/swipe_remote_datasource.dart';

class SwipeRepositoryImpl implements SwipeRepository {
  final SwipeRemoteDataSource _remoteDataSource;

  const SwipeRepositoryImpl({
    required SwipeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  }) {
    return _remoteDataSource.sendSwipe(propertyId: propertyId, action: action);
  }
}
DART

# Parches pequeños sobre ApiService para no reescribir todo el archivo si ya existe.
backup_file "frontend/lib/services/api_service.dart"
python3 - <<'PY'
from pathlib import Path
path = Path('frontend/lib/services/api_service.dart')
if not path.exists():
    raise SystemExit('No existe frontend/lib/services/api_service.dart')
text = path.read_text()

import_line = "import '../features/swipes/domain/entities/swipe_result.dart';"
if import_line not in text:
    anchor = "import '../features/properties/domain/entities/property.dart';"
    text = text.replace(anchor, anchor + "\n" + import_line)

text = text.replace("'/api/v1/properties',", "'/api/v1/properties/recommendations',", 1)

old = """  Future<void> sendSwipeAction(
    String propertyId,
    String action,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/swipes',
        data: {
          'property_id': propertyId,
          'action': action,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
"""
new = """  Future<SwipeResult> sendSwipeAction(
    String propertyId,
    String action,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/swipes',
        data: {
          'property_id': propertyId,
          'action': action,
        },
      );

      return SwipeResult.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
"""
if old in text:
    text = text.replace(old, new)
elif "Future<SwipeResult> sendSwipeAction" not in text:
    raise SystemExit('No pude parchear sendSwipeAction automáticamente. Revisa ApiService manualmente.')

path.write_text(text)
PY

# Parches sobre PropertyFeedScreen: invalidar providers tras swipe.
backup_file "frontend/lib/features/properties/presentation/screens/property_feed_screen.dart"
python3 - <<'PY'
from pathlib import Path
path = Path('frontend/lib/features/properties/presentation/screens/property_feed_screen.dart')
if not path.exists():
    raise SystemExit('No existe property_feed_screen.dart')
text = path.read_text()

import_line = "import '../providers/property_feed_controller.dart';"
if import_line not in text:
    anchor = "import '../widgets/property_card.dart';"
    text = text.replace(anchor, import_line + "\n" + anchor)

old = """  Future<void> _sendSwipe(
    WidgetRef ref, {
    required String propertyId,
    required String action,
  }) async {
    final useCase = ref.read(sendSwipeUseCaseProvider);

    try {
      await useCase(propertyId: propertyId, action: action);
    } catch (error) {
      debugPrint('Error enviando swipe: $error');
    }
  }
"""
new = """  Future<void> _sendSwipe(
    WidgetRef ref, {
    required String propertyId,
    required String action,
  }) async {
    final useCase = ref.read(sendSwipeUseCaseProvider);

    try {
      await useCase(propertyId: propertyId, action: action);
      ref.invalidate(propertyFeedProvider);
      ref.invalidate(propertiesProvider);
    } catch (error) {
      debugPrint('Error enviando swipe: $error');
    }
  }
"""
if old in text:
    text = text.replace(old, new)
elif 'ref.invalidate(propertyFeedProvider);' not in text:
    raise SystemExit('No pude parchear _sendSwipe automáticamente. Revisa property_feed_screen.dart manualmente.')

path.write_text(text)
PY

# ============================================================
# SQL/Docs manuales de Fase 6
# ============================================================

write_file "backend/supabase/fase6_zone_connections_optional.sql" <<'SQL'
-- ============================================================
-- RENT APP - FASE 6 OPCIONAL
-- Zonas y conexiones para grafo cargado desde DB.
-- Ejecutar manualmente en Supabase SQL Editor si todavía no existen.
-- ============================================================

create table if not exists public.zones (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  city text not null default 'Santa Cruz',
  created_at timestamptz not null default now()
);

create table if not exists public.zone_connections (
  id uuid primary key default gen_random_uuid(),
  from_zone_id uuid not null references public.zones(id) on delete cascade,
  to_zone_id uuid not null references public.zones(id) on delete cascade,
  distance_score int not null default 1,
  created_at timestamptz not null default now(),
  unique(from_zone_id, to_zone_id)
);

insert into public.zones (name)
values
  ('Equipetrol'),
  ('Centro'),
  ('Zona Norte'),
  ('Zona Sur'),
  ('Urubó')
on conflict (name) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Zona Norte'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Centro'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Urubó'
where z1.name = 'Equipetrol'
on conflict (from_zone_id, to_zone_id) do nothing;

insert into public.zone_connections (from_zone_id, to_zone_id, distance_score)
select z1.id, z2.id, 1
from public.zones z1
join public.zones z2 on z2.name = 'Zona Sur'
where z1.name = 'Centro'
on conflict (from_zone_id, to_zone_id) do nothing;
SQL

write_file "docs/fase6_swipe_recomendaciones_reales.md" <<'MD'
# Rent App — Fase 6 aplicada: Swipe y recomendaciones reales

Este script aplica únicamente la Fase 6 estructural.

## Cambios backend

- `backend/app/services/recommendation_service.py`
- `backend/app/domain/recommendation/scoring.py`
- `backend/app/domain/graphs/zone_graph.py`
- `backend/app/infrastructure/repositories/zone_repo.py`
- `backend/app/api/v1/endpoints/properties.py`
- `backend/app/services/swipe_service.py`
- `backend/app/schemas/swipe.py`
- Ajustes en repositorios de propiedades, swipes y matches.

## Cambios frontend

- `ApiService.fetchProperties()` ahora consume:

```txt
GET /api/v1/properties/recommendations
```

- `sendSwipeAction()` ahora devuelve `SwipeResult`.
- El feed invalida recomendaciones después de un swipe.

## Qué NO toca

- No toca Git.
- No instala dependencias.
- No modifica auth visual.
- No modifica market.
- No modifica owner dashboard salvo que el feed se refresque tras swipes.
- No hace deploy.

## Comprobaciones manuales recomendadas

Backend:

```bash
cd backend
python -m compileall app main.py
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Flutter:

```bash
cd frontend
flutter analyze
./run_linux.sh
```

Supabase opcional:

Si no tienes `zones` y `zone_connections`, puedes ejecutar manualmente:

```txt
backend/supabase/fase6_zone_connections_optional.sql
```

Si no lo ejecutas, el backend usa fallback con `city_graph.py`.
MD

# ============================================================
# Validaciones rápidas sin instalar nada
# ============================================================

info "Validando sintaxis Python del backend..."
(
  cd backend
  python3 -m compileall app main.py >/tmp/fase6_compileall.log
) || {
  cat /tmp/fase6_compileall.log >&2 || true
  fail "Falló compileall. Se creó backup en ${BACKUP_DIR}."
}

if command -v dart >/dev/null 2>&1; then
  info "Formateando archivos Dart modificados..."
  dart format \
    frontend/lib/services/api_service.dart \
    frontend/lib/features/properties/presentation/screens/property_feed_screen.dart \
    frontend/lib/features/swipes/domain/entities/swipe_result.dart \
    frontend/lib/features/swipes/domain/repositories/swipe_repository.dart \
    frontend/lib/features/swipes/domain/usecases/send_swipe_usecase.dart \
    frontend/lib/features/swipes/data/datasources/swipe_remote_datasource.dart \
    frontend/lib/features/swipes/data/repositories/swipe_repository_impl.dart >/dev/null || warn "dart format falló; revisa formato manualmente."
else
  warn "No encontré dart en PATH; no se formatearon archivos Dart."
fi

info "Fase 6 aplicada correctamente."
info "Archivos de respaldo: ${BACKUP_DIR}"
info "Documento generado: docs/fase6_swipe_recomendaciones_reales.md"
info "SQL opcional: backend/supabase/fase6_zone_connections_optional.sql"

cat <<'NEXT'

Siguiente comprobación manual sugerida:

cd backend
python -m compileall app main.py
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Luego en Flutter:

cd frontend
flutter analyze
./run_linux.sh

Prueba funcional:
1. Login.
2. Onboarding con Alquiler + 5000 + Equipetrol.
3. Ver feed.
4. Swipe derecha.
5. Confirmar que desaparece del feed al refrescar.
6. Revisar matches.

NEXT
