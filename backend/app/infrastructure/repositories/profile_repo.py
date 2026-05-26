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
