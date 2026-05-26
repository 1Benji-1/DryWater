"""Reglas de negocio de amenidades."""

from app.infrastructure.repositories.amenity_repo import AmenityRepository


class AmenityService:
    """Servicio de amenidades."""

    def __init__(self, repository: AmenityRepository | None = None):
        self.repository = repository or AmenityRepository()

    def list_amenities(self) -> list[str]:
        """Lista amenities disponibles para formularios."""

        return self.repository.list_amenity_names()
