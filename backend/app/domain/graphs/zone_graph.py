"""Grafo de zonas cargable desde base de datos.

Fase 6 evita depender únicamente de zonas hardcodeadas. Si Supabase todavía
no tiene `zones` y `zone_connections`, se usa el grafo anterior como fallback.
"""

from __future__ import annotations

from collections import defaultdict, deque
from typing import Any

from app.domain.graphs.city_graph import grafo_scz


class ZoneGraph:
    """Grafo no dirigido para calcular cercanía por BFS."""

    def __init__(self, adjacency: dict[str, list[str]] | None = None):
        self.adjacency = adjacency or {}

    @classmethod
    def from_connection_rows(cls, rows: list[dict[str, Any]]) -> "ZoneGraph":
        """Construye grafo desde filas de Supabase.

        Soporta varias formas porque el esquema puede venir como IDs, nombres
        directos o relaciones embebidas de Supabase.
        """

        adjacency: dict[str, set[str]] = defaultdict(set)

        for row in rows:
            from_zone = cls._extract_zone_name(row, "from")
            to_zone = cls._extract_zone_name(row, "to")

            if not from_zone or not to_zone:
                continue

            adjacency[from_zone].add(to_zone)
            adjacency[to_zone].add(from_zone)

        return cls({key: sorted(value) for key, value in adjacency.items()})

    @staticmethod
    def _extract_zone_name(row: dict[str, Any], prefix: str) -> str:
        """Extrae nombre de zona desde distintas variantes de columnas."""

        direct_keys = (
            f"{prefix}_zone",
            f"{prefix}_zone_name",
            f"{prefix}_zone_label",
            f"{prefix}_zone_id",
        )
        for key in direct_keys:
            value = row.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()

        nested = row.get(f"{prefix}_zone")
        if isinstance(nested, dict):
            for key in ("name", "label", "zone"):
                value = nested.get(key)
                if isinstance(value, str) and value.strip():
                    return value.strip()

        return ""

    def bfs_recorrido_cercania(self, start_zone: str) -> list[str]:
        """Devuelve zonas por cercanía usando cola FIFO."""

        if not start_zone:
            return []

        if start_zone not in self.adjacency:
            fallback = grafo_scz.bfs_recorrido_cercania(start_zone)
            return fallback if fallback else [start_zone]

        result: list[str] = []
        visited = {start_zone}
        queue: deque[str] = deque([start_zone])

        while queue:
            current = queue.popleft()
            result.append(current)

            for neighbor in self.adjacency.get(current, []):
                if neighbor not in visited:
                    visited.add(neighbor)
                    queue.append(neighbor)

        return result


def build_zone_graph(rows: list[dict[str, Any]]) -> ZoneGraph:
    """Crea grafo desde DB o fallback al grafo actual."""

    graph = ZoneGraph.from_connection_rows(rows)
    if graph.adjacency:
        return graph

    return ZoneGraph(adjacency=grafo_scz.adyacencias)
