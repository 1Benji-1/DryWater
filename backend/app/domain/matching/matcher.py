# Archivo: backend/app/domain/matching/matcher.py

class MatchMaker:
    @staticmethod
    def calcular_compatibilidad(requisitos_cliente: set, amenidades_inmueble: set) -> float:
        """
        Fórmula: (|A ∩ B| / |A|) * 100
        Calcula qué porcentaje de los requisitos del cliente son satisfecidos por la casa.
        """
        if not requisitos_cliente:
            return 100.0  # Si no exige nada, el match es perfecto
        
        interseccion = requisitos_cliente.intersection(amenidades_inmueble)
        match_score = (len(interseccion) / len(requisitos_cliente)) * 100
        
        return round(match_score, 2)
        
    @staticmethod
    def buscar_mejores_opciones(requisitos_cliente: set, presupuesto_max: float, todos_los_inmuebles: list, matriz_amenidades) -> list:
        """Filtra por presupuesto y ordena los inmuebles usando el ADT Conjunto."""
        resultados = []
        
        for casa in todos_los_inmuebles:
            precio = float(casa['precio_bs'])
            
            if precio <= presupuesto_max:
                id_casa = casa['id_inmueble']
                amenidades_casa = matriz_amenidades.obtener_amenidades_de_inmueble(id_casa)
                
                score = MatchMaker.calcular_compatibilidad(requisitos_cliente, amenidades_casa)
                
                # Diferencia de conjuntos (A - B) para saber qué le falta a la casa
                faltantes = list(requisitos_cliente.difference(amenidades_casa))
                
                if score > 0:
                    resultados.append({
                        "id_inmueble": id_casa,
                        "zona": casa['zona'],
                        "precio_bs": precio,
                        "match_score": score,
                        "amenidades_faltantes": faltantes
                    })
                    
        # Ordenar de mayor a menor Match
        return sorted(resultados, key=lambda x: x['match_score'], reverse=True)