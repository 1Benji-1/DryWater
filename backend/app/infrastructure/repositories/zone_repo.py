"""Repositorio de zonas y conexiones para recomendaciones."""

from app.infrastructure.supabase.client import get_supabase_client


class ZoneRepository:
    """Acceso a `zones` y `zone_connections`.

    Si las tablas todavía no existen, devuelve lista vacía para que el
    servicio use el fallback de `city_graph.py`.
    """

    def __init__(self):
        self.client = get_supabase_client()

    def list_zone_connections(self) -> list[dict]:
        """Lista conexiones entre zonas de Supabase si están disponibles."""

        queries = (
            "from_zone:zones!zone_connections_from_zone_id_fkey(name),"
            "to_zone:zones!zone_connections_to_zone_id_fkey(name),"
            "distance_score",
            "from_zone_name,to_zone_name,distance_score",
            "from_zone,to_zone,distance_score",
            "from_zone_id,to_zone_id,distance_score",
        )

        for select_query in queries:
            try:
                response = (
                    self.client.table("zone_connections")
                    .select(select_query)
                    .execute()
                )
                rows = response.data or []
                if rows:
                    return rows
            except Exception:
                continue

        return []
