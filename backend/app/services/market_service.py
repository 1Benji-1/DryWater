"""Reglas de negocio de análisis de mercado."""

from typing import Any

from fastapi import HTTPException, status

from app.domain.market.analyzer import MarketAnalyzer
from app.infrastructure.repositories.market_repo import MarketRepository
from app.schemas.market import (
    MarketEvaluationRequest,
    MarketEvaluationResponse,
    MarketStatisticsResponse,
    QuartilesResponse,
)


class MarketService:
    """Servicio de evaluación estadística de precios."""

    def __init__(self, repository: MarketRepository | None = None):
        self.repository = repository or MarketRepository()

    @staticmethod
    def build_statistics(
        stats: dict[str, Any],
        sample_size: int,
        prices: list[float],
    ) -> MarketStatisticsResponse:
        """Convierte estadísticas del dominio al schema público de la API."""

        quartiles = stats.get("quartiles", {})
        sorted_prices = sorted(prices)
        return MarketStatisticsResponse(
            mean=float(stats.get("mean", 0)),
            median=quartiles.get("q2"),
            min_price=sorted_prices[0] if sorted_prices else None,
            max_price=sorted_prices[-1] if sorted_prices else None,
            standard_deviation=stats.get("standard_deviation"),
            coefficient_of_variation=stats.get("coefficient_of_variation"),
            quartiles=QuartilesResponse(
                q1=float(quartiles.get("q1", 0)),
                q2=float(quartiles.get("q2", 0)),
                q3=float(quartiles.get("q3", 0)),
            ),
            sample_size=sample_size,
        )

    def evaluate_price(self, request: MarketEvaluationRequest) -> MarketEvaluationResponse:
        """Evalúa un precio usando comparables por operación, zona y tipo."""

        prices = self.repository.list_market_prices(
            operation_type=request.operation_type,
            zone=request.zone,
            property_type=request.property_type,
        )
        if not prices:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No hay datos suficientes para esa operación, zona o tipo.",
            )

        stats = MarketAnalyzer.calcular_estadisticas_zona(prices)
        evaluation = MarketAnalyzer.evaluar_precio(request.price, stats)
        return MarketEvaluationResponse(
            statistical_analysis=self.build_statistics(stats, len(prices), prices),
            price_verdict=evaluation,
        )
