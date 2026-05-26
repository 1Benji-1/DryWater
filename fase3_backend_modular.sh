#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# RENT APP - FASE 3 BACKEND MODULAR
# ------------------------------------------------------------
# Este script refactoriza el backend FastAPI para cerrar Fase 3:
# - Hace commit de seguridad ANTES de tocar archivos.
# - Crea router api/v1 y endpoints separados.
# - Implementa services reales.
# - Separa repositorios por recurso.
# - Deja routes.py como legacy sin uso.
# - Actualiza main.py para usar app.api.v1.router.
# - Crea tests mínimos y ejecuta comprobaciones.
#
# Uso recomendado desde la raíz del proyecto:
#   chmod +x fase3_backend_modular.sh
#   ./fase3_backend_modular.sh
# ============================================================

PROJECT_ROOT="$(pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
APP_DIR="$BACKEND_DIR/app"
LOG_FILE="$PROJECT_ROOT/fase3_backend_modular.log"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_BRANCH="backup/fase3-before-$TIMESTAMP"
WORK_BRANCH="refactor/fase3-backend-modular"

log() {
  printf '\n[FASE 3] %s\n' "$1" | tee -a "$LOG_FILE"
}

fail() {
  printf '\n[ERROR] %s\n' "$1" | tee -a "$LOG_FILE" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "No existe el archivo requerido: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "No existe la carpeta requerida: $path"
}

replace_in_file() {
  local file_path="$1"
  local old_text="$2"
  local new_text="$3"
  python3 - "$file_path" "$old_text" "$new_text" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
old = sys.argv[2]
new = sys.argv[3]
text = path.read_text(encoding="utf-8")
if old not in text:
    raise SystemExit(f"No se encontró el texto esperado en {path}: {old!r}")
path.write_text(text.replace(old, new), encoding="utf-8")
PY
}

log "Validando que estás en la raíz del proyecto..."
require_dir "$BACKEND_DIR"
require_dir "$APP_DIR"
require_file "$BACKEND_DIR/main.py"
require_file "$APP_DIR/api/routes.py"
require_file "$APP_DIR/api/dependencies.py"
require_file "$APP_DIR/core/config.py"
require_file "$APP_DIR/infrastructure/supabase/client.py"

if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
  fail "No estás en una raíz Git. Entra a ~/Descargas/rent_app_phase1 o la carpeta raíz real del proyecto."
fi

log "Preparando commit de seguridad antes de tocar Fase 3..."
git add .
# Commit vacío intencional: garantiza punto de retorno aunque no hubiera cambios.
git commit --allow-empty -m "backup antes de fase 3 backend modular $TIMESTAMP" | tee -a "$LOG_FILE"

git branch "$BACKUP_BRANCH" >/dev/null 2>&1 || true
log "Backup marcado en rama: $BACKUP_BRANCH"

if git show-ref --verify --quiet "refs/heads/$WORK_BRANCH"; then
  git checkout "$WORK_BRANCH" | tee -a "$LOG_FILE"
else
  git checkout -b "$WORK_BRANCH" | tee -a "$LOG_FILE"
fi

log "Creando estructura backend modular..."
mkdir -p "$APP_DIR/api/v1/endpoints"
mkdir -p "$APP_DIR/services"
mkdir -p "$APP_DIR/infrastructure/repositories"
mkdir -p "$BACKEND_DIR/tests"
mkdir -p "$BACKEND_DIR/supabase"
mkdir -p "$PROJECT_ROOT/docs"

touch "$APP_DIR/api/v1/__init__.py"
touch "$APP_DIR/api/v1/endpoints/__init__.py"
touch "$APP_DIR/infrastructure/__init__.py" || true
touch "$APP_DIR/infrastructure/repositories/__init__.py"
touch "$APP_DIR/services/__init__.py"

log "Respaldando routes.py como legacy..."
cp "$APP_DIR/api/routes.py" "$APP_DIR/api/routes_legacy_fase3_$TIMESTAMP.py"
cat > "$APP_DIR/api/routes.py" <<'PY'
"""LEGACY FASE 3.

Este archivo queda intencionalmente sin rutas activas.
Las rutas reales de producción están en:

    app/api/v1/router.py
    app/api/v1/endpoints/

No importar este router desde main.py.
"""

from fastapi import APIRouter

router = APIRouter()
PY

log "Creando utilidades compartidas..."
mkdir -p "$APP_DIR/utils"
touch "$APP_DIR/utils/__init__.py"
cat > "$APP_DIR/utils/pagination.py" <<'PY'
"""Utilidades de paginación para respuestas API."""

from app.schemas.common import PaginationMeta


def build_pagination(page: int, page_size: int, total: int) -> PaginationMeta:
    """Construye metadatos de paginación consistentes."""

    return PaginationMeta(
        page=page,
        page_size=page_size,
        total=total,
        has_next=(page * page_size) < total,
    )
PY

# ============================================================
# REPOSITORIOS SEPARADOS
# ============================================================

log "Creando repositorios separados por recurso..."

cat > "$APP_DIR/infrastructure/repositories/profile_repo.py" <<'PY'
"""Repositorio de perfiles y roles en Supabase."""

from app.infrastructure.supabase.client import get_supabase_client


class ProfileRepository:
    """Acceso a datos de profiles."""

    def __init__(self):
        self.client = get_supabase_client()

    def get_profile(self, user_id: str, email: str | None = None) -> dict:
        """Obtiene perfil. Si no existe, lo crea como buyer."""

        response = (
            self.client.table("profiles")
            .select("*")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        if rows:
            profile = rows[0]
            profile["email"] = email
            return profile

        full_name = email.split("@")[0] if email else "Usuario"
        created = (
            self.client.table("profiles")
            .insert({"id": user_id, "full_name": full_name, "role": "buyer"})
            .execute()
        )
        profile = (created.data or [{}])[0]
        profile["email"] = email
        return profile

    def update_profile(
        self,
        user_id: str,
        full_name: str | None = None,
        phone: str | None = None,
        email: str | None = None,
    ) -> dict:
        """Actualiza nombre/teléfono del perfil."""

        payload: dict[str, str] = {}
        if full_name is not None:
            payload["full_name"] = full_name.strip()
        if phone is not None:
            payload["phone"] = phone.strip()

        if payload:
            self.client.table("profiles").update(payload).eq("id", user_id).execute()

        return self.get_profile(user_id=user_id, email=email)

    def become_owner(self, user_id: str, email: str | None = None) -> dict:
        """Activa rol owner al usuario actual."""

        self.get_profile(user_id=user_id, email=email)
        self.client.table("profiles").update({"role": "owner"}).eq(
            "id", user_id
        ).execute()
        return self.get_profile(user_id=user_id, email=email)

    def is_owner_or_admin(self, user_id: str) -> bool:
        """Verifica si el usuario puede usar panel de propietario."""

        profile = self.get_profile(user_id)
        return profile.get("role") in {"owner", "admin"}
PY

cat > "$APP_DIR/infrastructure/repositories/preference_repo.py" <<'PY'
"""Repositorio de preferencias de usuario."""

from app.infrastructure.supabase.client import get_supabase_client


class PreferenceRepository:
    """Acceso a datos de user_preferences."""

    def __init__(self):
        self.client = get_supabase_client()

    def upsert_user_preferences(
        self,
        user_id: str,
        max_budget: float,
        operation_type: str,
        preferred_zone: str,
    ) -> None:
        """Crea o actualiza preferencias del usuario."""

        self.client.table("user_preferences").upsert(
            {
                "user_id": user_id,
                "max_budget": max_budget,
                "operation_type": operation_type,
                "preferred_zone": preferred_zone,
            },
            on_conflict="user_id",
        ).execute()

    def get_user_preferences(self, user_id: str) -> dict | None:
        """Obtiene preferencias del usuario."""

        response = (
            self.client.table("user_preferences")
            .select("*")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        return rows[0] if rows else None
PY

cat > "$APP_DIR/infrastructure/repositories/amenity_repo.py" <<'PY'
"""Repositorio de amenidades."""

from app.infrastructure.supabase.client import get_supabase_client


class AmenityRepository:
    """Acceso a amenities y property_amenities."""

    def __init__(self):
        self.client = get_supabase_client()

    def list_amenity_names(self) -> list[str]:
        """Lista amenities disponibles."""

        response = self.client.table("amenities").select("name").order("name").execute()
        return [str(row["name"]) for row in (response.data or [])]

    def get_or_create_amenity_ids(self, names: list[str]) -> list[str]:
        """Obtiene IDs de amenities, creando las que no existan."""

        clean_names = sorted({name.strip() for name in names if name.strip()})
        if not clean_names:
            return []

        for name in clean_names:
            self.client.table("amenities").upsert(
                {"name": name},
                on_conflict="name",
            ).execute()

        response = (
            self.client.table("amenities")
            .select("id,name")
            .in_("name", clean_names)
            .execute()
        )
        return [str(row["id"]) for row in (response.data or [])]

    def replace_property_amenities(
        self,
        property_id: str,
        amenity_names: list[str],
    ) -> None:
        """Reemplaza amenities asociadas a una propiedad."""

        self.client.table("property_amenities").delete().eq(
            "property_id", property_id
        ).execute()

        amenity_ids = self.get_or_create_amenity_ids(amenity_names)
        if not amenity_ids:
            return

        rows = [
            {"property_id": property_id, "amenity_id": amenity_id}
            for amenity_id in amenity_ids
        ]
        self.client.table("property_amenities").insert(rows).execute()
PY

cat > "$APP_DIR/infrastructure/repositories/property_image_repo.py" <<'PY'
"""Repositorio de imágenes de propiedades."""

from app.infrastructure.supabase.client import get_supabase_client


class PropertyImageRepository:
    """Acceso a property_images."""

    def __init__(self):
        self.client = get_supabase_client()

    def insert_property_images(self, property_id: str, images: list[dict]) -> None:
        """Inserta imágenes de una propiedad ya subida a Supabase Storage."""

        if not images:
            return

        rows = []
        for index, image in enumerate(images):
            image_url = str(image.get("image_url") or "").strip()
            storage_path = image.get("storage_path")
            if not image_url:
                continue

            rows.append(
                {
                    "property_id": property_id,
                    "image_url": image_url,
                    "storage_path": storage_path,
                    "sort_order": index,
                }
            )

        if rows:
            self.client.table("property_images").insert(rows).execute()
PY

cat > "$APP_DIR/infrastructure/repositories/swipe_repo.py" <<'PY'
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

cat > "$APP_DIR/infrastructure/repositories/match_repo.py" <<'PY'
"""Repositorio de matches."""

from app.infrastructure.supabase.client import get_supabase_client


class MatchRepository:
    """Acceso a matches y consultas relacionadas."""

    def __init__(self):
        self.client = get_supabase_client()

    def upsert_match(self, buyer_id: str, owner_id: str, property_id: str) -> None:
        """Crea o mantiene activo un match."""

        self.client.table("matches").upsert(
            {
                "buyer_id": buyer_id,
                "owner_id": owner_id,
                "property_id": property_id,
                "status": "active",
            },
            on_conflict="buyer_id,property_id",
        ).execute()

    def delete_match(self, buyer_id: str, property_id: str) -> None:
        """Elimina match cuando el swipe cambia a nope."""

        self.client.table("matches").delete().eq("buyer_id", buyer_id).eq(
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
        buyer_ids = [str(row["buyer_id"]) for row in matches]

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
        if buyer_ids:
            buyers_response = (
                self.client.table("profiles")
                .select("*")
                .in_("id", buyer_ids)
                .execute()
            )
            buyers_by_id = {
                str(buyer["id"]): buyer for buyer in (buyers_response.data or [])
            }

        enriched = []
        for match in matches:
            property_id = str(match.get("property_id"))
            buyer_id = str(match.get("buyer_id"))
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
        if user_id not in {str(match.get("buyer_id")), str(match.get("owner_id"))}:
            return False

        self.client.table("matches").update({"status": status}).eq(
            "id", match_id
        ).execute()
        return True
PY

cat > "$APP_DIR/infrastructure/repositories/market_repo.py" <<'PY'
"""Repositorio de datos comparables para mercado."""

from app.infrastructure.supabase.client import get_supabase_client


class MarketRepository:
    """Acceso a property_cards para análisis estadístico."""

    def __init__(self):
        self.client = get_supabase_client()

    def list_market_prices(
        self,
        operation_type: str,
        zone: str | None = None,
        property_type: str | None = None,
    ) -> list[float]:
        """Devuelve precios comparables para análisis de mercado."""

        query = (
            self.client.table("property_cards")
            .select("price,operation_type,zone,property_type,status")
            .eq("status", "available")
        )

        response = query.execute()
        cards = response.data or []
        prices = []

        for card in cards:
            if str(card.get("operation_type", "")).lower() != operation_type.lower():
                continue
            if zone and str(card.get("zone", "")).lower() != zone.lower():
                continue
            if property_type and str(card.get("property_type", "")).lower() != property_type.lower():
                continue

            price = float(card.get("price") or 0)
            if price > 0:
                prices.append(price)

        return prices
PY

cat > "$APP_DIR/infrastructure/repositories/property_repo.py" <<'PY'
"""Repositorio de propiedades.

Fase 3: este archivo ya no concentra perfil, swipes, matches ni market.
Cada recurso vive en su repositorio dedicado.
"""

from app.domain.graphs.city_graph import grafo_scz
from app.infrastructure.repositories.amenity_repo import AmenityRepository
from app.infrastructure.repositories.preference_repo import PreferenceRepository
from app.infrastructure.repositories.profile_repo import ProfileRepository
from app.infrastructure.repositories.property_image_repo import PropertyImageRepository
from app.infrastructure.repositories.swipe_repo import SwipeRepository
from app.infrastructure.supabase.client import get_supabase_client


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
        """Lista propiedades disponibles desde la view normalizada."""

        response = (
            self.client.table("property_cards")
            .select("*")
            .eq("status", "available")
            .execute()
        )
        return response.data or []

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
        """Lista propiedades recomendadas/no vistas según preferencias."""

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
            if float(card.get("price") or 0) > max_budget:
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

# ============================================================
# SERVICES
# ============================================================

log "Implementando services reales..."

cat > "$APP_DIR/services/profile_service.py" <<'PY'
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
PY

cat > "$APP_DIR/services/onboarding_service.py" <<'PY'
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
PY

cat > "$APP_DIR/services/amenity_service.py" <<'PY'
"""Reglas de negocio de amenidades."""

from app.infrastructure.repositories.amenity_repo import AmenityRepository


class AmenityService:
    """Servicio de amenidades."""

    def __init__(self, repository: AmenityRepository | None = None):
        self.repository = repository or AmenityRepository()

    def list_amenities(self) -> list[str]:
        """Lista amenities disponibles para formularios."""

        return self.repository.list_amenity_names()
PY

cat > "$APP_DIR/services/property_service.py" <<'PY'
"""Reglas de negocio para propiedades públicas/recomendadas."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.property import (
    PropertyDetailResponse,
    PropertyListResponse,
    PropertySummaryResponse,
)
from app.utils.pagination import build_pagination


class PropertyService:
    """Servicio de propiedades."""

    def __init__(self, repository: PropertyRepository | None = None):
        self.repository = repository or PropertyRepository()

    def list_for_user(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> PropertyListResponse:
        """Obtiene propiedades recomendadas/no vistas del usuario autenticado."""

        rows, total = self.repository.list_cards_for_user(
            user_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return PropertyListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
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

cat > "$APP_DIR/services/owner_property_service.py" <<'PY'
"""Reglas de negocio del panel de propietario."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.property_repo import PropertyRepository
from app.schemas.common import SuccessResponse
from app.schemas.owner_property import (
    OwnerPropertyCreateRequest,
    OwnerPropertyListResponse,
    OwnerPropertyStatusRequest,
)
from app.schemas.property import PropertyDetailResponse, PropertySummaryResponse
from app.services.profile_service import ProfileService
from app.utils.pagination import build_pagination


class OwnerPropertyService:
    """Servicio de propiedades de owner."""

    def __init__(
        self,
        property_repository: PropertyRepository | None = None,
        profile_service: ProfileService | None = None,
    ):
        self.property_repository = property_repository or PropertyRepository()
        self.profile_service = profile_service or ProfileService()

    def list_owner_properties(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> OwnerPropertyListResponse:
        """Lista propiedades creadas por el owner."""

        self.profile_service.ensure_owner(current_user)
        rows, total = self.property_repository.list_owner_cards(
            owner_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return OwnerPropertyListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def create_property(
        self,
        current_user: CurrentUser,
        request: OwnerPropertyCreateRequest,
    ) -> PropertyDetailResponse:
        """Crea una propiedad publicada por el owner."""

        row = self.property_repository.create_owner_property(
            owner_id=current_user.id,
            payload=request.model_dump(),
        )
        return PropertyDetailResponse.from_supabase_row(row)

    def update_status(
        self,
        current_user: CurrentUser,
        property_id: str,
        request: OwnerPropertyStatusRequest,
    ) -> PropertyDetailResponse:
        """Actualiza estado de una propiedad propia."""

        self.profile_service.ensure_owner(current_user)
        row = self.property_repository.update_owner_property_status(
            owner_id=current_user.id,
            property_id=property_id,
            new_status=request.status,
        )
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La propiedad no existe o no te pertenece.",
            )
        return PropertyDetailResponse.from_supabase_row(row)

    def soft_delete(self, current_user: CurrentUser, property_id: str) -> SuccessResponse:
        """Oculta una propiedad propia."""

        self.profile_service.ensure_owner(current_user)
        deleted = self.property_repository.soft_delete_owner_property(
            owner_id=current_user.id,
            property_id=property_id,
        )
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="La propiedad no existe o no te pertenece.",
            )
        return SuccessResponse(message="Propiedad ocultada correctamente.")
PY

cat > "$APP_DIR/services/swipe_service.py" <<'PY'
"""Reglas de negocio de swipes."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
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

        self.swipe_repository.upsert_swipe(
            user_id=current_user.id,
            property_id=request.property_id,
            action=request.action,
        )

        is_match = False
        if request.action == "like":
            owner_id = str(row.get("owner_id") or "")
            if owner_id:
                self.match_repository.upsert_match(
                    buyer_id=current_user.id,
                    owner_id=owner_id,
                    property_id=request.property_id,
                )
                is_match = True
        else:
            self.match_repository.delete_match(
                buyer_id=current_user.id,
                property_id=request.property_id,
            )

        return SwipeResponse(
            message="Interacción procesada correctamente.",
            property_id=request.property_id,
            action=request.action,
            is_match=is_match,
        )
PY

cat > "$APP_DIR/services/match_service.py" <<'PY'
"""Reglas de negocio de matches."""

from fastapi import HTTPException, status

from app.api.dependencies import CurrentUser
from app.infrastructure.repositories.match_repo import MatchRepository
from app.schemas.common import SuccessResponse
from app.schemas.match import MatchListResponse
from app.schemas.owner_property import (
    MatchStatusUpdateRequest,
    OwnerMatchListResponse,
    OwnerMatchResponse,
)
from app.schemas.property import PropertySummaryResponse
from app.services.profile_service import ProfileService
from app.utils.pagination import build_pagination


class MatchService:
    """Servicio de matches para buyer y owner."""

    def __init__(
        self,
        repository: MatchRepository | None = None,
        profile_service: ProfileService | None = None,
    ):
        self.repository = repository or MatchRepository()
        self.profile_service = profile_service or ProfileService()

    def list_buyer_matches(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> MatchListResponse:
        """Devuelve propiedades likeadas por el usuario autenticado."""

        rows, total = self.repository.list_match_cards(
            user_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [PropertySummaryResponse.from_supabase_row(row) for row in rows]
        return MatchListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def list_owner_matches(
        self,
        current_user: CurrentUser,
        page: int,
        page_size: int,
    ) -> OwnerMatchListResponse:
        """Devuelve interesados en propiedades del propietario."""

        self.profile_service.ensure_owner(current_user)
        rows, total = self.repository.list_owner_matches(
            owner_id=current_user.id,
            page=page,
            page_size=page_size,
        )
        items = [
            OwnerMatchResponse(
                match_id=row["match_id"],
                status=row["status"],
                buyer_id=row["buyer_id"],
                buyer_name=row.get("buyer_name"),
                buyer_email=row.get("buyer_email"),
                property=PropertySummaryResponse.from_supabase_row(row["property"]),
            )
            for row in rows
        ]
        return OwnerMatchListResponse(
            items=items,
            pagination=build_pagination(page, page_size, total),
        )

    def update_status(
        self,
        current_user: CurrentUser,
        match_id: str,
        request: MatchStatusUpdateRequest,
    ) -> SuccessResponse:
        """Actualiza estado active/contacted/archived."""

        updated = self.repository.update_match_status(
            user_id=current_user.id,
            match_id=match_id,
            status=request.status,
        )
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="El match no existe o no te pertenece.",
            )
        return SuccessResponse(message="Match actualizado correctamente.")
PY

cat > "$APP_DIR/services/market_service.py" <<'PY'
"""Reglas de negocio de análisis de mercado."""

from typing import Any

from fastapi import HTTPException, status

from app.domain.market.analyzer import MarketAnalyzer
from app.infrastructure.repositories.market_repo import MarketRepository
from app.schemas.market import (
    MarketEvaluationRequest,
    MarketEvaluationResponse,
    MarketStatisticsResponse,
    QuartilesResponse,
)


class MarketService:
    """Servicio de evaluación estadística de precios."""

    def __init__(self, repository: MarketRepository | None = None):
        self.repository = repository or MarketRepository()

    @staticmethod
    def build_statistics(
        stats: dict[str, Any],
        sample_size: int,
        prices: list[float],
    ) -> MarketStatisticsResponse:
        """Convierte estadísticas del dominio al schema público de la API."""

        quartiles = stats.get("quartiles", {})
        sorted_prices = sorted(prices)
        return MarketStatisticsResponse(
            mean=float(stats.get("mean", 0)),
            median=quartiles.get("q2"),
            min_price=sorted_prices[0] if sorted_prices else None,
            max_price=sorted_prices[-1] if sorted_prices else None,
            standard_deviation=stats.get("standard_deviation"),
            coefficient_of_variation=stats.get("coefficient_of_variation"),
            quartiles=QuartilesResponse(
                q1=float(quartiles.get("q1", 0)),
                q2=float(quartiles.get("q2", 0)),
                q3=float(quartiles.get("q3", 0)),
            ),
            sample_size=sample_size,
        )

    def evaluate_price(self, request: MarketEvaluationRequest) -> MarketEvaluationResponse:
        """Evalúa un precio usando comparables por operación, zona y tipo."""

        prices = self.repository.list_market_prices(
            operation_type=request.operation_type,
            zone=request.zone,
            property_type=request.property_type,
        )
        if not prices:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No hay datos suficientes para esa operación, zona o tipo.",
            )

        stats = MarketAnalyzer.calcular_estadisticas_zona(prices)
        evaluation = MarketAnalyzer.evaluar_precio(request.price, stats)
        return MarketEvaluationResponse(
            statistical_analysis=self.build_statistics(stats, len(prices), prices),
            price_verdict=evaluation,
        )
PY

# compatibility alias in case old code imports valuation_service
cat > "$APP_DIR/services/valuation_service.py" <<'PY'
"""Compatibilidad: el análisis de precio ahora vive en MarketService."""

from app.services.market_service import MarketService

ValuationService = MarketService
PY

# ============================================================
# ENDPOINTS
# ============================================================

log "Creando endpoints separados por recurso..."

cat > "$APP_DIR/api/v1/router.py" <<'PY'
"""Router principal v1 de Rent App API."""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    amenities,
    health,
    market,
    matches,
    onboarding,
    owner_properties,
    profile,
    properties,
    swipes,
)

api_router = APIRouter()

api_router.include_router(health.router, tags=["health"])
api_router.include_router(profile.router, tags=["profile"])
api_router.include_router(onboarding.router, tags=["onboarding"])
api_router.include_router(amenities.router, tags=["amenities"])
api_router.include_router(properties.router, tags=["properties"])
api_router.include_router(owner_properties.router, tags=["owner-properties"])
api_router.include_router(swipes.router, tags=["swipes"])
api_router.include_router(matches.router, tags=["matches"])
api_router.include_router(market.router, tags=["market"])
PY

cat > "$APP_DIR/api/v1/endpoints/health.py" <<'PY'
"""Endpoints de healthcheck."""

from fastapi import APIRouter

from app.core.config import get_settings

router = APIRouter()


@router.get("/health")
def health_check_v1() -> dict[str, str]:
    """Healthcheck versionado para monitoreo."""

    settings = get_settings()
    return {
        "status": "ok",
        "environment": settings.environment,
        "storage": "supabase",
    }
PY

cat > "$APP_DIR/api/v1/endpoints/profile.py" <<'PY'
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
PY

cat > "$APP_DIR/api/v1/endpoints/onboarding.py" <<'PY'
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
PY

cat > "$APP_DIR/api/v1/endpoints/amenities.py" <<'PY'
"""Endpoints de amenidades."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.services.amenity_service import AmenityService

router = APIRouter()


@router.get("/amenities", response_model=list[str])
async def listar_amenities(
    current_user: CurrentUser = Depends(get_current_user),
) -> list[str]:
    """Lista amenities disponibles para formularios."""

    return AmenityService().list_amenities()
PY

cat > "$APP_DIR/api/v1/endpoints/properties.py" <<'PY'
"""Endpoints de propiedades para buyer."""

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.property import PropertyDetailResponse, PropertyListResponse
from app.services.property_service import PropertyService

router = APIRouter()


@router.get("/properties", response_model=PropertyListResponse)
async def obtener_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyListResponse:
    """Obtiene propiedades no vistas del usuario autenticado."""

    return PropertyService().list_for_user(current_user, page, page_size)


@router.get("/properties/{property_id}", response_model=PropertyDetailResponse)
async def obtener_detalle_propiedad(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Obtiene detalle normalizado de una propiedad."""

    return PropertyService().get_detail(property_id)
PY

cat > "$APP_DIR/api/v1/endpoints/owner_properties.py" <<'PY'
"""Endpoints de propiedades del propietario."""

from fastapi import APIRouter, Depends, Query, status

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.common import SuccessResponse
from app.schemas.owner_property import (
    OwnerPropertyCreateRequest,
    OwnerPropertyListResponse,
    OwnerPropertyStatusRequest,
)
from app.schemas.property import PropertyDetailResponse
from app.services.owner_property_service import OwnerPropertyService

router = APIRouter()


@router.get("/owner/properties", response_model=OwnerPropertyListResponse)
async def listar_mis_propiedades(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerPropertyListResponse:
    """Lista propiedades creadas por el owner."""

    return OwnerPropertyService().list_owner_properties(current_user, page, page_size)


@router.post(
    "/owner/properties",
    response_model=PropertyDetailResponse,
    status_code=status.HTTP_201_CREATED,
)
async def crear_propiedad_owner(
    request: OwnerPropertyCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Crea una propiedad publicada por el owner."""

    return OwnerPropertyService().create_property(current_user, request)


@router.patch(
    "/owner/properties/{property_id}/status",
    response_model=PropertyDetailResponse,
)
async def actualizar_estado_propiedad_owner(
    property_id: str,
    request: OwnerPropertyStatusRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> PropertyDetailResponse:
    """Actualiza estado de una propiedad propia."""

    return OwnerPropertyService().update_status(current_user, property_id, request)


@router.delete("/owner/properties/{property_id}", response_model=SuccessResponse)
async def eliminar_propiedad_owner(
    property_id: str,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Oculta una propiedad propia."""

    return OwnerPropertyService().soft_delete(current_user, property_id)
PY

cat > "$APP_DIR/api/v1/endpoints/swipes.py" <<'PY'
"""Endpoints de swipes."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.swipe import SwipeRequest, SwipeResponse
from app.services.swipe_service import SwipeService

router = APIRouter()


@router.post("/swipes", response_model=SwipeResponse)
async def registrar_swipe(
    swipe: SwipeRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SwipeResponse:
    """Registra like/nope del usuario autenticado."""

    return SwipeService().record_swipe(current_user, swipe)
PY

cat > "$APP_DIR/api/v1/endpoints/matches.py" <<'PY'
"""Endpoints de matches."""

from fastapi import APIRouter, Depends, Query

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.common import SuccessResponse
from app.schemas.match import MatchListResponse
from app.schemas.owner_property import MatchStatusUpdateRequest, OwnerMatchListResponse
from app.services.match_service import MatchService

router = APIRouter()


@router.get("/matches", response_model=MatchListResponse)
async def obtener_matches_usuario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> MatchListResponse:
    """Devuelve propiedades likeadas por el usuario autenticado."""

    return MatchService().list_buyer_matches(current_user, page, page_size)


@router.get("/owner/matches", response_model=OwnerMatchListResponse)
async def obtener_matches_propietario(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
) -> OwnerMatchListResponse:
    """Devuelve interesados en propiedades del propietario."""

    return MatchService().list_owner_matches(current_user, page, page_size)


@router.patch("/matches/{match_id}/status", response_model=SuccessResponse)
async def actualizar_estado_match(
    match_id: str,
    request: MatchStatusUpdateRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SuccessResponse:
    """Actualiza estado active/contacted/archived."""

    return MatchService().update_status(current_user, match_id, request)
PY

cat > "$APP_DIR/api/v1/endpoints/market.py" <<'PY'
"""Endpoints de análisis de mercado."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.market import MarketEvaluationRequest, MarketEvaluationResponse
from app.services.market_service import MarketService

router = APIRouter()


@router.post("/market/evaluate", response_model=MarketEvaluationResponse)
def evaluar_precio_mercado(
    request: MarketEvaluationRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> MarketEvaluationResponse:
    """Evalúa un precio usando comparables por operación, zona y tipo."""

    return MarketService().evaluate_price(request)
PY

# ============================================================
# MAIN.PY
# ============================================================

log "Actualizando backend/main.py para usar router v1 modular..."
python3 - <<'PY'
from pathlib import Path

path = Path("backend/main.py")
text = path.read_text(encoding="utf-8")
text = text.replace("from app.api.routes import router", "from app.api.v1.router import api_router")
text = text.replace(
    "app.include_router(router, prefix=\"/api/v1\", tags=[\"api-v1\"])",
    "app.include_router(api_router, prefix=\"/api/v1\")",
)
text = text.replace(
    "API de Rent App. Fase 2 conecta Supabase Auth, ",
    "API de Rent App. Fase 3 usa backend modular, ",
)
path.write_text(text, encoding="utf-8")
PY

# ============================================================
# SQL PLACEHOLDERS VERSIONADOS
# ============================================================

log "Creando archivos SQL versionados si no existen..."
for sql_file in schema policies storage seed; do
  target="$BACKEND_DIR/supabase/${sql_file}.sql"
  if [[ ! -f "$target" ]]; then
    cat > "$target" <<SQL
-- Rent App - ${sql_file}.sql
-- TODO: Pegar aquí el SQL real ejecutado en Supabase para versionarlo en Git.
-- Este archivo existe para cerrar la trazabilidad Fase 2/Fase 3.
SQL
  fi
done

# ============================================================
# DOCUMENTACIÓN DE FASE 3
# ============================================================

log "Creando documentación/checklist de Fase 3..."
cat > "$PROJECT_ROOT/docs/fase3_backend_modular.md" <<'MD'
# Rent App — Fase 3 Backend Modular

Este refactor separa el backend siguiendo:

```txt
endpoint -> schema -> service -> repository -> Supabase/PostgreSQL
```

## Cambios aplicados

- `backend/main.py` ahora usa `app.api.v1.router`.
- `backend/app/api/routes.py` quedó como legacy sin rutas activas.
- Endpoints separados en `backend/app/api/v1/endpoints/`.
- Services implementados en `backend/app/services/`.
- Repositorios separados en `backend/app/infrastructure/repositories/`.
- Market se movió a `MarketService`.
- Swipes se movieron a `SwipeService`.
- Matches se movieron a `MatchService`.
- Owner properties se movió a `OwnerPropertyService`.
- Perfil/roles se movió a `ProfileService`.

## Comprobaciones rápidas

```bash
cd backend
python -m compileall app main.py
python -m pytest -q
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Luego abrir:

```txt
http://127.0.0.1:8000/health
http://127.0.0.1:8000/api/v1/health
http://127.0.0.1:8000/docs
```
MD

# ============================================================
# REQUIREMENTS Y TESTS
# ============================================================

log "Actualizando requirements.txt con dependencias de test si faltan..."
python3 - <<'PY'
from pathlib import Path

path = Path("backend/requirements.txt")
text = path.read_text(encoding="utf-8") if path.exists() else ""
lines = text.splitlines()
existing = {line.split("==")[0].split(">=")[0].split("<")[0].strip().lower() for line in lines if line.strip() and not line.startswith("#")}
for dep in ["pytest", "httpx"]:
    if dep.lower() not in existing:
        lines.append(dep)
path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY

log "Creando tests mínimos de Fase 3..."
cat > "$BACKEND_DIR/tests/test_fase3_structure.py" <<'PY'
"""Tests estructurales de Fase 3."""

from pathlib import Path


def test_main_uses_modular_router():
    text = Path("main.py").read_text(encoding="utf-8")
    assert "from app.api.v1.router import api_router" in text
    assert "from app.api.routes import router" not in text
    assert "app.include_router(api_router, prefix=\"/api/v1\")" in text


def test_required_endpoint_files_exist():
    base = Path("app/api/v1/endpoints")
    expected = {
        "health.py",
        "profile.py",
        "onboarding.py",
        "amenities.py",
        "properties.py",
        "owner_properties.py",
        "swipes.py",
        "matches.py",
        "market.py",
    }
    existing = {path.name for path in base.glob("*.py")}
    assert expected.issubset(existing)


def test_required_services_exist_and_are_not_empty():
    base = Path("app/services")
    expected = {
        "profile_service.py",
        "onboarding_service.py",
        "amenity_service.py",
        "property_service.py",
        "owner_property_service.py",
        "swipe_service.py",
        "match_service.py",
        "market_service.py",
    }
    for name in expected:
        path = base / name
        assert path.exists(), f"Falta {path}"
        assert len(path.read_text(encoding="utf-8").splitlines()) > 10


def test_required_repositories_exist():
    base = Path("app/infrastructure/repositories")
    expected = {
        "profile_repo.py",
        "preference_repo.py",
        "amenity_repo.py",
        "property_image_repo.py",
        "property_repo.py",
        "swipe_repo.py",
        "match_repo.py",
        "market_repo.py",
    }
    existing = {path.name for path in base.glob("*.py")}
    assert expected.issubset(existing)
PY

cat > "$BACKEND_DIR/tests/test_fase3_api.py" <<'PY'
"""Tests básicos de API Fase 3 sin depender de token real."""

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_api_v1_health_ok():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_openapi_contains_final_routes():
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    expected = [
        "/api/v1/me",
        "/api/v1/onboarding",
        "/api/v1/amenities",
        "/api/v1/properties",
        "/api/v1/properties/{property_id}",
        "/api/v1/owner/properties",
        "/api/v1/swipes",
        "/api/v1/matches",
        "/api/v1/owner/matches",
        "/api/v1/matches/{match_id}/status",
        "/api/v1/market/evaluate",
    ]
    for path in expected:
        assert path in paths


def test_me_requires_auth():
    response = client.get("/api/v1/me")
    assert response.status_code in {401, 403}
PY

# ============================================================
# COMPROBACIONES AUTOMÁTICAS
# ============================================================

log "Ejecutando comprobaciones automáticas de Fase 3..."
cd "$BACKEND_DIR"

log "1/6: compileall"
python3 -m compileall app main.py | tee -a "$LOG_FILE"

log "2/6: import main y listar rutas"
python3 - <<'PY' | tee -a "$LOG_FILE"
from main import app
routes = sorted(getattr(route, "path", "") for route in app.routes)
required = [
    "/api/v1/health",
    "/api/v1/me",
    "/api/v1/onboarding",
    "/api/v1/amenities",
    "/api/v1/properties",
    "/api/v1/properties/{property_id}",
    "/api/v1/owner/properties",
    "/api/v1/swipes",
    "/api/v1/matches",
    "/api/v1/owner/matches",
    "/api/v1/matches/{match_id}/status",
    "/api/v1/market/evaluate",
]
missing = [path for path in required if path not in routes]
print("Rutas registradas:")
for path in required:
    print(f"  {'OK' if path in routes else 'FALTA'} {path}")
if missing:
    raise SystemExit(f"Faltan rutas: {missing}")
PY

log "3/6: verificar que main.py ya no importe app.api.routes"
if grep -R "from app.api.routes import router" main.py app >/tmp/fase3_routes_import.txt 2>/dev/null; then
  cat /tmp/fase3_routes_import.txt | tee -a "$LOG_FILE"
  fail "Todavía existe import legacy de app.api.routes."
fi

log "4/6: verificar services con contenido"
find app/services -type f -name "*.py" -maxdepth 1 -exec wc -l {} \; | tee -a "$LOG_FILE"

log "5/6: ejecutar pytest si está instalado"
if python3 - <<'PY' >/dev/null 2>&1
import pytest  # noqa: F401
PY
then
  python3 -m pytest -q | tee -a "$LOG_FILE"
else
  log "pytest no está instalado en este entorno. Instala con: cd backend && source venv/bin/activate && pip install -r requirements.txt"
fi

log "6/6: resumen Git"
cd "$PROJECT_ROOT"
git status --short | tee -a "$LOG_FILE"
git diff --stat | tee -a "$LOG_FILE"

log "FASE 3 aplicada. Revisa el log: $LOG_FILE"
cat <<'TXT'

============================================================
SIGUIENTES COMPROBACIONES MANUALES RECOMENDADAS
============================================================

1) Levantar backend:
   cd backend
   source venv/bin/activate
   pip install -r requirements.txt
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload

2) Abrir en navegador:
   http://127.0.0.1:8000/health
   http://127.0.0.1:8000/api/v1/health
   http://127.0.0.1:8000/docs

3) Probar flujo con token real desde Flutter:
   - Login
   - Onboarding
   - Feed properties
   - Swipe like/nope
   - Matches
   - Owner properties
   - Market evaluate

4) Si todo funciona, hacer commit final:
   git add .
   git commit -m "fase 3 backend modular completada"

5) Si algo sale mal, volver al backup:
   git checkout backup/fase3-before-YYYYMMDD_HHMMSS

============================================================
TXT
