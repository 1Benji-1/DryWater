"""Endpoints de análisis de mercado."""

from fastapi import APIRouter, Depends

from app.api.dependencies import CurrentUser, get_current_user
from app.schemas.market import MarketEvaluationRequest, MarketEvaluationResponse
from app.services.market_service import MarketService

router = APIRouter()


@router.post("/market/evaluate", response_model=MarketEvaluationResponse)
def evaluar_precio_mercado(
    request: MarketEvaluationRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> MarketEvaluationResponse:
    """Evalúa un precio usando comparables por operación, zona y tipo."""

    return MarketService().evaluate_price(request)
