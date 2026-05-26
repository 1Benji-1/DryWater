"""Tests básicos de API Fase 3 sin depender de token real."""

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_api_v1_health_ok():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_openapi_contains_final_routes():
    response = client.get("/openapi.json")
    assert response.status_code == 200
    paths = response.json()["paths"]
    expected = [
        "/api/v1/me",
        "/api/v1/onboarding",
        "/api/v1/amenities",
        "/api/v1/properties",
        "/api/v1/properties/{property_id}",
        "/api/v1/owner/properties",
        "/api/v1/swipes",
        "/api/v1/matches",
        "/api/v1/owner/matches",
        "/api/v1/matches/{match_id}/status",
        "/api/v1/market/evaluate",
    ]
    for path in expected:
        assert path in paths


def test_me_requires_auth():
    response = client.get("/api/v1/me")
    assert response.status_code in {401, 403}
