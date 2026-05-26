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
