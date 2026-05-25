"""Schemas para evaluación estadística de mercado."""

from pydantic import BaseModel, Field


class MarketEvaluationRequest(BaseModel):
    """Solicitud de análisis de mercado para una propiedad."""

    price: float = Field(..., gt=0, examples=[3500])
    operation_type: str = Field(..., min_length=1, examples=["Alquiler"])
    zone: str | None = Field(default=None, examples=["Equipetrol"])
    property_type: str | None = Field(default=None, examples=["Departamento"])


class QuartilesResponse(BaseModel):
    """Cuartiles normalizados para Flutter."""

    q1: float
    q2: float
    q3: float


class MarketStatisticsResponse(BaseModel):
    """Estadísticas limpias para la UI."""

    mean: float
    median: float | None = None
    min_price: float | None = None
    max_price: float | None = None
    standard_deviation: float | None = None
    coefficient_of_variation: float | None = None
    quartiles: QuartilesResponse
    sample_size: int


class MarketEvaluationResponse(BaseModel):
    """Respuesta final del análisis de mercado."""

    statistical_analysis: MarketStatisticsResponse
    price_verdict: str

