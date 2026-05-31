"""Repositorio de matches.

Fase 7 deja de listar matches del buyer desde `swipes` y pasa a usar la
tabla `matches` como fuente real. Se mantiene compatibilidad con esquemas que
usen `buyer_id` o `user_id`.
"""

from app.domain.matches.match_status import normalize_match_status
from app.infrastructure.supabase.client import get_supabase_client


class MatchRepository:
    """Acceso a matches y consultas relacionadas."""

    def __init__(self):
        self.client = get_supabase_client()

    def upsert_match(self, buyer_id: str, owner_id: str, property_id: str) -> str | None:
        """Crea o reactiva un match y devuelve su ID si Supabase lo retorna."""

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

    def _list_matches_by_buyer(self, buyer_id: str) -> list[dict]:
        """Lista matches reales del buyer con fallback buyer_id/user_id."""

        try:
            response = (
                self.client.table("matches")
                .select("*")
                .eq("buyer_id", buyer_id)
                .order("created_at", desc=True)
                .execute()
            )
        except Exception:
            response = (
                self.client.table("matches")
                .select("*")
                .eq("user_id", buyer_id)
                .order("created_at", desc=True)
                .execute()
            )

        return response.data or []

    def _get_match_by_id(self, match_id: str) -> dict | None:
        """Obtiene un match crudo por ID."""

        response = (
            self.client.table("matches")
            .select("*")
            .eq("id", match_id)
            .limit(1)
            .execute()
        )
        rows = response.data or []
        return rows[0] if rows else None

    def _get_cards_by_id(self, property_ids: list[str]) -> dict[str, dict]:
        """Carga tarjetas normalizadas desde la view property_cards."""

        clean_ids = [item for item in property_ids if item]
        if not clean_ids:
            return {}

        response = (
            self.client.table("property_cards")
            .select("*")
            .in_("id", clean_ids)
            .execute()
        )
        return {str(card["id"]): card for card in (response.data or [])}

    def _get_profiles_by_id(self, profile_ids: list[str]) -> dict[str, dict]:
        """Carga perfiles públicos necesarios para contacto."""

        clean_ids = [item for item in profile_ids if item]
        if not clean_ids:
            return {}

        response = (
            self.client.table("profiles")
            .select("id, full_name, phone")
            .in_("id", clean_ids)
            .execute()
        )
        return {str(profile["id"]): profile for profile in (response.data or [])}

    def _enrich_buyer_matches(self, matches: list[dict]) -> list[dict]:
        """Agrega propiedad y datos de owner a los matches del buyer."""

        property_ids = [str(row.get("property_id") or "") for row in matches]
        owner_ids = [str(row.get("owner_id") or "") for row in matches]
        cards_by_id = self._get_cards_by_id(property_ids)
        owners_by_id = self._get_profiles_by_id(owner_ids)

        enriched: list[dict] = []
        for match in matches:
            property_id = str(match.get("property_id") or "")
            owner_id = str(match.get("owner_id") or "")
            card = cards_by_id.get(property_id)
            owner = owners_by_id.get(owner_id, {})
            if not card:
                continue

            enriched.append(
                {
                    "match_id": str(match.get("id")),
                    "status": normalize_match_status(match.get("status")),
                    "owner_id": owner_id or None,
                    "owner_name": owner.get("full_name"),
                    "owner_phone": owner.get("phone"),
                    "property": card,
                }
            )

        return enriched

    def list_match_cards(
        self,
        user_id: str,
        page: int,
        page_size: int,
    ) -> tuple[list[dict], int]:
        """Devuelve matches reales del buyer."""

        matches = self._list_matches_by_buyer(user_id)
        enriched = self._enrich_buyer_matches(matches)

        total = len(enriched)
        start = (page - 1) * page_size
        end = start + page_size
        return enriched[start:end], total

    def get_buyer_match_detail(self, user_id: str, match_id: str) -> dict | None:
        """Devuelve detalle de un match si pertenece al buyer u owner."""

        match = self._get_match_by_id(match_id)
        if not match:
            return None

        buyer_id = str(match.get("buyer_id") or match.get("user_id") or "")
        owner_id = str(match.get("owner_id") or "")
        if user_id not in {buyer_id, owner_id}:
            return None

        enriched = self._enrich_buyer_matches([match])
        return enriched[0] if enriched else None

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
        property_ids = [str(row.get("property_id") or "") for row in matches]
        buyer_ids = [str(row.get("buyer_id") or row.get("user_id") or "") for row in matches]

        cards_by_id = self._get_cards_by_id(property_ids)
        buyers_by_id = self._get_profiles_by_id(buyer_ids)

        enriched: list[dict] = []
        for match in matches:
            property_id = str(match.get("property_id") or "")
            buyer_id = str(match.get("buyer_id") or match.get("user_id") or "")
            card = cards_by_id.get(property_id)
            buyer = buyers_by_id.get(buyer_id, {})
            if not card:
                continue

            enriched.append(
                {
                    "match_id": str(match.get("id")),
                    "status": normalize_match_status(match.get("status")),
                    "buyer_id": buyer_id,
                    "buyer_name": buyer.get("full_name"),
                    "buyer_email": None,
                    "buyer_phone": buyer.get("phone"),
                    "property": card,
                }
            )

        total = len(enriched)
        start = (page - 1) * page_size
        end = start + page_size
        return enriched[start:end], total

    def update_match_status(self, user_id: str, match_id: str, status: str) -> bool:
        """Actualiza estado si el match pertenece al buyer u owner."""

        match = self._get_match_by_id(match_id)
        if not match:
            return False

        buyer_id = str(match.get("buyer_id") or match.get("user_id") or "")
        owner_id = str(match.get("owner_id") or "")
        if user_id not in {buyer_id, owner_id}:
            return False

        self.client.table("matches").update(
            {"status": normalize_match_status(status)}
        ).eq("id", match_id).execute()
        return True
