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
