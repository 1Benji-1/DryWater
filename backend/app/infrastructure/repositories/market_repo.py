"""Repositorio de datos comparables para mercado."""

from app.infrastructure.supabase.client import get_supabase_client


class MarketRepository:
    """Acceso a property_cards para análisis estadístico."""

    def __init__(self):
        self.client = get_supabase_client()

    def list_market_prices(
        self,
        operation_type: str,
        zone: str | None = None,
        property_type: str | None = None,
    ) -> list[float]:
        """Devuelve precios comparables para análisis de mercado."""

        query = (
            self.client.table("property_cards")
            .select("price,operation_type,zone,property_type,status")
            .eq("status", "available")
        )

        response = query.execute()
        cards = response.data or []
        prices = []

        for card in cards:
            if str(card.get("operation_type", "")).lower() != operation_type.lower():
                continue
            if zone and str(card.get("zone", "")).lower() != zone.lower():
                continue
            if property_type and str(card.get("property_type", "")).lower() != property_type.lower():
                continue

            price = float(card.get("price") or 0)
            if price > 0:
                prices.append(price)

        return prices
