# Archivo: backend/app/domain/matching/matcher.py


class MatchMaker:
    @staticmethod
    def calcular_compatibilidad(
        required_amenities: set[str],
        property_amenities: set[str],
    ) -> float:
        """Calcula el porcentaje de requisitos cubiertos por una propiedad."""

        if not required_amenities:
            return 100.0

        intersection = required_amenities.intersection(property_amenities)
        score = (len(intersection) / len(required_amenities)) * 100

        return round(score, 2)

    @staticmethod
    def buscar_mejores_opciones(
        required_amenities: set[str],
        max_budget: float,
        properties: list[dict],
    ) -> list[dict]:
        """Filtra por presupuesto y ordena propiedades por compatibilidad."""

        results = []

        for property_data in properties:
            price = float(property_data.get("price") or 0)

            if price > max_budget:
                continue

            property_amenities = set(property_data.get("amenities") or [])
            score = MatchMaker.calcular_compatibilidad(
                required_amenities=required_amenities,
                property_amenities=property_amenities,
            )
            missing_amenities = list(required_amenities.difference(property_amenities))

            if score > 0:
                results.append(
                    {
                        "id": property_data.get("id"),
                        "zone": property_data.get("zone"),
                        "price": price,
                        "match_score": score,
                        "missing_amenities": missing_amenities,
                    }
                )

        return sorted(results, key=lambda item: item["match_score"], reverse=True)

