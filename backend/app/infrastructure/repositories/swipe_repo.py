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
