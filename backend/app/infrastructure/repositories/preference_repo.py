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
