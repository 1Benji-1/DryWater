"""Compatibilidad: el análisis de precio ahora vive en MarketService."""

from app.services.market_service import MarketService

ValuationService = MarketService
