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
