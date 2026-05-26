"""Tests estructurales de Fase 3."""

from pathlib import Path


def test_main_uses_modular_router():
    text = Path("main.py").read_text(encoding="utf-8")
    assert "from app.api.v1.router import api_router" in text
    assert "from app.api.routes import router" not in text
    assert "app.include_router(api_router, prefix=\"/api/v1\")" in text


def test_required_endpoint_files_exist():
    base = Path("app/api/v1/endpoints")
    expected = {
        "health.py",
        "profile.py",
        "onboarding.py",
        "amenities.py",
        "properties.py",
        "owner_properties.py",
        "swipes.py",
        "matches.py",
        "market.py",
    }
    existing = {path.name for path in base.glob("*.py")}
    assert expected.issubset(existing)


def test_required_services_exist_and_are_not_empty():
    base = Path("app/services")
    expected = {
        "profile_service.py",
        "onboarding_service.py",
        "amenity_service.py",
        "property_service.py",
        "owner_property_service.py",
        "swipe_service.py",
        "match_service.py",
        "market_service.py",
    }
    for name in expected:
        path = base / name
        assert path.exists(), f"Falta {path}"
        assert len(path.read_text(encoding="utf-8").splitlines()) > 10


def test_required_repositories_exist():
    base = Path("app/infrastructure/repositories")
    expected = {
        "profile_repo.py",
        "preference_repo.py",
        "amenity_repo.py",
        "property_image_repo.py",
        "property_repo.py",
        "swipe_repo.py",
        "match_repo.py",
        "market_repo.py",
    }
    existing = {path.name for path in base.glob("*.py")}
    assert expected.issubset(existing)
