"""Repositorio conectado a Supabase.

Fase 3 agrega:
- Perfil y rol owner.
- Creación de propiedades.
- Imágenes en property_images.
- Amenidades.
- Matches visibles para propietario.
"""

from app.domain.graphs.city_graph import grafo_scz
from app.infrastructure.supabase.client import get_supabase_client


class SupabasePropertyRepository:
    """Repositorio productivo para propiedades, preferencias, swipes y matches."""

    def __init__(self):
        self.client = get_supabase_client()

    # ========================================================
    # PROFILE / ROLES
    # ========================================================

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
            .insert(
                {
                    "id": user_id,
                    "full_name": full_name,
                    "role": "buyer",
                }
            )
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

        payload = {}

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

    # ========================================================
    # USER PREFERENCES
    # ========================================================

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

    # ========================================================
    # PROPERTY READS
    # ========================================================

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

    def list_swiped_property_ids(self, user_id: str) -> set[str]:
        """Devuelve IDs de propiedades ya vistas por el usuario."""

        response = (
            self.client.table("swipes")
            .select("property_id")
            .eq("user_id", user_id)
            .execute()
        )
        return {str(row["property_id"]) for row in (response.data or [])}

    def get_last_liked_zone(self, user_id: str) -> str | None:
        """Obtiene la última zona likeada para priorizar el mazo."""

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
        if not rows:
            return None

        property_id = rows[0].get("property_id")
        card = self.find_card_by_id(str(property_id))
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

        preferences = self.get_user_preferences(user_id)
        if not preferences:
            return [], 0

        max_budget = float(preferences.get("max_budget") or 0)
        operation_type = str(preferences.get("operation_type") or "")
        preferred_zone = str(preferences.get("preferred_zone") or "")

        swiped_ids = self.list_swiped_property_ids(user_id)
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

    def count_available_for_preferences(
        self,
        max_budget: float,
        operation_type: str,
    ) -> int:
        """Cuenta propiedades disponibles para el onboarding."""

        cards = self.list_available_cards()
        return sum(
            1
            for card in cards
            if str(card.get("operation_type", "")).lower() == operation_type.lower()
            and float(card.get("price") or 0) <= max_budget
        )

    # ========================================================
    # OWNER PROPERTIES
    # ========================================================

    def list_amenity_names(self) -> list[str]:
        """Lista amenities disponibles."""

        response = self.client.table("amenities").select("name").order("name").execute()
        return [str(row["name"]) for row in (response.data or [])]

    def _get_or_create_amenity_ids(self, names: list[str]) -> list[str]:
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

    def _replace_property_amenities(
        self,
        property_id: str,
        amenity_names: list[str],
    ) -> None:
        """Reemplaza amenities asociadas a una propiedad."""

        self.client.table("property_amenities").delete().eq(
            "property_id", property_id
        ).execute()

        amenity_ids = self._get_or_create_amenity_ids(amenity_names)
        if not amenity_ids:
            return

        rows = [
            {
                "property_id": property_id,
                "amenity_id": amenity_id,
            }
            for amenity_id in amenity_ids
        ]

        self.client.table("property_amenities").insert(rows).execute()

    def _insert_property_images(
        self,
        property_id: str,
        images: list[dict],
    ) -> None:
        """Inserta imágenes de una propiedad."""

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

    def create_owner_property(
        self,
        owner_id: str,
        payload: dict,
    ) -> dict:
        """Crea un inmueble publicado por el owner."""

        self.become_owner(owner_id)

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

        self._replace_property_amenities(
            property_id=property_id,
            amenity_names=payload.get("amenities") or [],
        )

        self._insert_property_images(
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

    def soft_delete_owner_property(
        self,
        owner_id: str,
        property_id: str,
    ) -> bool:
        """Oculta una propiedad sin eliminar datos históricos."""

        card = self.update_owner_property_status(
            owner_id=owner_id,
            property_id=property_id,
            new_status="hidden",
        )

        return card is not None

    # ========================================================
    # SWIPES / MATCHES
    # ========================================================

    def record_swipe(
        self,
        user_id: str,
        property_id: str,
        action: str,
    ) -> bool:
        """Registra like/nope y crea match si corresponde."""

        card = self.find_card_by_id(property_id)
        if not card:
            return False

        self.client.table("swipes").upsert(
            {
                "user_id": user_id,
                "property_id": property_id,
                "action": action,
            },
            on_conflict="user_id,property_id",
        ).execute()

        if action == "like":
            self.client.table("matches").upsert(
                {
                    "buyer_id": user_id,
                    "owner_id": card.get("owner_id"),
                    "property_id": property_id,
                    "status": "active",
                },
                on_conflict="buyer_id,property_id",
            ).execute()
            return True

        self.client.table("matches").delete().eq("buyer_id", user_id).eq(
            "property_id", property_id
        ).execute()
        return False

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

    def update_match_status(
        self,
        user_id: str,
        match_id: str,
        status: str,
    ) -> bool:
        """Actualiza estado de un match si pertenece al usuario."""

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

    # ========================================================
    # MARKET
    # ========================================================

    def list_market_prices(
        self,
        operation_type: str,
        zone: str | None = None,
        property_type: str | None = None,
    ) -> list[float]:
        """Devuelve precios comparables para análisis de mercado."""

        cards = self.list_available_cards()
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


repo_inmuebles = SupabasePropertyRepository()
