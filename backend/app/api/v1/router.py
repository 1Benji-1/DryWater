"""Router principal v1 de Weather Alerts API."""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    health,
    onboarding,
    profile,
    weather,
)

api_router = APIRouter()

api_router.include_router(health.router, tags=["health"])
api_router.include_router(profile.router, tags=["profile"])
api_router.include_router(onboarding.router, tags=["onboarding"])
api_router.include_router(weather.router, tags=["weather"])
