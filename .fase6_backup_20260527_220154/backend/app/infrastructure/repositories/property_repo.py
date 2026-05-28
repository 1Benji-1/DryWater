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
