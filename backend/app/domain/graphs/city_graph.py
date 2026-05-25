# Archivo: backend/app/domain/graphs/city_graph.py
from collections import deque
from typing import List, Dict

class GrafoZonasUrbana:
    """Representación geográfica de Santa Cruz usando diccionarios y listas nativas."""
    def __init__(self):
        # El mapa de adyacencias de tu CSV (Zonas conectadas geográficamente)
        self.adyacencias: Dict[str, List[str]] = {
            "Equipetrol": ["Zona Norte", "Centro", "Urubó"],
            "Centro": ["Equipetrol", "Zona Norte", "Zona Sur"],
            "Zona Norte": ["Equipetrol", "Centro"],
            "Urubó": ["Equipetrol"],
            "Zona Sur": ["Centro"]
        }

    def bfs_recorrido_cercania(self, zona_inicial: str) -> List[str]:
        """
        Recorre la ciudad nivel por nivel usando 'deque' (la cola FIFO nativa de Python).
        Devuelve la ruta de expansión óptima según cercanía.
        """
        if zona_inicial not in self.adyacencias:
            return [zona_inicial]

        resultado = []
        visitados = {zona_inicial} # Set nativo para evitar duplicados
        cola = deque([zona_inicial]) # Cola FIFO nativa optimizada

        while cola:
            zona_actual = cola.popleft() # Desencolar (O(1))
            resultado.append(zona_actual)

            # Explorar vecinos
            for vecino in self.adyacencias[zona_actual]:
                if vecino not in visitados:
                    visitados.add(vecino)
                    cola.append(vecino) # Encolar (O(1))

        return resultado

# Instancia lista para producción
grafo_scz = GrafoZonasUrbana()