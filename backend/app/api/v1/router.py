"""Router principal v1 de Rent App API."""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    amenities,
    health,
    market,
    matches,
    onboarding,
    owner_properties,
    profile,
    properties,
    swipes,
)

api_router = APIRouter()

api_router.include_router(health.router, tags=["health"])
api_router.include_router(profile.router, tags=["profile"])
api_router.include_router(onboarding.router, tags=["onboarding"])
api_router.include_router(amenities.router, tags=["amenities"])
api_router.include_router(properties.router, tags=["properties"])
api_router.include_router(owner_properties.router, tags=["owner-properties"])
api_router.include_router(swipes.router, tags=["swipes"])
api_router.include_router(matches.router, tags=["matches"])
api_router.include_router(market.router, tags=["market"])
